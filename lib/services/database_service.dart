import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_entry.dart';
import 'encryption_service.dart';

/// 数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  final _encryption = EncryptionService();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'password_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passwords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            url TEXT,
            notes TEXT,
            category TEXT NOT NULL DEFAULT '其他',
            tags TEXT NOT NULL DEFAULT '[]',
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            passwordHistory TEXT NOT NULL DEFAULT '[]'
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_category ON passwords(category)
        ''');

        await db.execute('''
          CREATE INDEX idx_title ON passwords(title)
        ''');
      },
    );
  }

  /// 添加密码条目
  Future<int> insertPassword(PasswordEntry entry) async {
    final db = await database;
    // 加密密码后再存储
    final encryptedPassword = _encryption.encrypt(entry.password);
    final encryptedEntry = entry.copyWith(password: encryptedPassword);
    
    return await db.insert('passwords', encryptedEntry.toMap());
  }

  /// 更新密码条目
  Future<int> updatePassword(PasswordEntry entry) async {
    final db = await database;
    
    // 如果密码变了，把旧密码加入历史
    final oldEntry = await getPasswordById(entry.id!);
    List<String> newHistory = List.from(entry.passwordHistory);
    
    if (oldEntry != null && oldEntry.password != entry.password) {
      newHistory.insert(0, oldEntry.password);
      if (newHistory.length > 5) {
        newHistory = newHistory.sublist(0, 5); // 只保留最近5个
      }
    }

    final encryptedPassword = _encryption.encrypt(entry.password);
    final updatedEntry = entry.copyWith(
      password: encryptedPassword,
      passwordHistory: newHistory,
      updatedAt: DateTime.now(),
    );

    return await db.update(
      'passwords',
      updatedEntry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// 删除密码条目
  Future<int> deletePassword(int id) async {
    final db = await database;
    return await db.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有密码（解密后）
  Future<List<PasswordEntry>> getAllPasswords() async {
    final db = await database;
    final List<Map> maps = await db.query('passwords', orderBy: 'updatedAt DESC');
    
    return maps.map((map) {
      final entry = PasswordEntry.fromMap(Map<String, dynamic>.from(map));
      // 解密密码
      try {
        final decryptedPassword = _encryption.decrypt(entry.password);
        return entry.copyWith(password: decryptedPassword);
      } catch (e) {
        // 解密失败返回原值
        return entry;
      }
    }).toList();
  }

  /// 根据ID获取密码
  Future<PasswordEntry?> getPasswordById(int id) async {
    final db = await database;
    final List<Map> maps = await db.query(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final entry = PasswordEntry.fromMap(Map<String, dynamic>.from(maps.first));
    try {
      final decryptedPassword = _encryption.decrypt(entry.password);
      return entry.copyWith(password: decryptedPassword);
    } catch (e) {
      return entry;
    }
  }

  /// 搜索密码
  Future<List<PasswordEntry>> searchPasswords(String query) async {
    final db = await database;
    final List<Map> maps = await db.query(
      'passwords',
      where: 'title LIKE ? OR username LIKE ? OR url LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) {
      final entry = PasswordEntry.fromMap(Map<String, dynamic>.from(map));
      try {
        final decryptedPassword = _encryption.decrypt(entry.password);
        return entry.copyWith(password: decryptedPassword);
      } catch (e) {
        return entry;
      }
    }).toList();
  }

  /// 按分类获取密码
  Future<List<PasswordEntry>> getPasswordsByCategory(String category) async {
    final db = await database;
    final List<Map> maps = await db.query(
      'passwords',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) {
      final entry = PasswordEntry.fromMap(Map<String, dynamic>.from(map));
      try {
        final decryptedPassword = _encryption.decrypt(entry.password);
        return entry.copyWith(password: decryptedPassword);
      } catch (e) {
        return entry;
      }
    }).toList();
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM passwords ORDER BY category'
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  /// 清空数据库（用于退出登录）
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('passwords');
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}