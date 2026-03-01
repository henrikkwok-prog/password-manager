import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/password_entry.dart';
import 'database_service.dart';
import 'encryption_service.dart';

/// 备份数据模型
class BackupData {
  final String version;
  final DateTime createdAt;
  final List<PasswordEntry> passwords;
  final Map<String, dynamic> metadata;

  BackupData({
    required this.version,
    required this.createdAt,
    required this.passwords,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'passwords': passwords.map((p) => p.toMap()).toList(),
      'metadata': metadata,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt']),
      passwords: (json['passwords'] as List)
          .map((p) => PasswordEntry.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// 备份服务
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _db = DatabaseService();
  final _encryption = EncryptionService();

  /// 导出备份
  Future<String?> exportBackup({bool encrypt = true}) async {
    try {
      // 请求存储权限
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // 获取所有密码
      final passwords = await _db.getAllPasswords();

      // 创建备份数据
      final backup = BackupData(
        version: '1.0.0',
        createdAt: DateTime.now(),
        passwords: passwords,
        metadata: {
          'appName': 'Password Manager',
          'exportDate': DateTime.now().toIso8601String(),
          'count': passwords.length,
        },
      );

      // 转换为 JSON
      var jsonString = jsonEncode(backup.toJson());

      // 可选：加密备份文件
      if (encrypt) {
        jsonString = _encryption.encrypt(jsonString);
      }

      // 保存到下载目录
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'password_backup_$timestamp.pmbak';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonString);

      // 分享文件
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '密码备份 - ${DateTime.now().toString().split('.')[0]}',
      );

      return filePath;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  /// 导入备份
  Future<bool> importBackup() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pmbak', 'json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.first.path!);
      var content = await file.readAsString();

      // 尝试解密（如果是加密的）
      try {
        content = _encryption.decrypt(content);
      } catch (e) {
        // 不是加密文件，直接使用
      }

      // 解析 JSON
      final json = jsonDecode(content);
      final backup = BackupData.fromJson(json);

      // 导入到数据库
      for (final entry in backup.passwords) {
        await _db.insertPassword(entry);
      }

      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  /// 导出为 CSV（用于迁移到其他密码管理器）
  Future<String?> exportToCSV() async {
    try {
      final passwords = await _db.getAllPasswords();
      
      // CSV 头部
      final csv = StringBuffer();
      csv.writeln('name,url,username,password,note');
      
      for (final entry in passwords) {
        // 转义 CSV 中的特殊字符
        final name = _escapeCsv(entry.title);
        final url = _escapeCsv(entry.url ?? '');
        final username = _escapeCsv(entry.username);
        final password = _escapeCsv(entry.password);
        final note = _escapeCsv(entry.notes ?? '');
        
        csv.writeln('$name,$url,$username,$password,$note');
      }

      // 保存文件
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/password_export_$timestamp.csv';

      final file = File(filePath);
      await file.writeAsString(csv.toString());

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '密码导出 CSV',
      );

      return filePath;
    } catch (e) {
      print('CSV export error: $e');
      return null;
    }
  }

  /// 从 CSV 导入
  Future<bool> importFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.first.path!);
      final lines = await file.readAsLines();

      // 跳过头部
      for (var i = 1; i < lines.length; i++) {
        final parts = _parseCsvLine(lines[i]);
        if (parts.length >= 4) {
          final entry = PasswordEntry(
            title: parts[0],
            url: parts[1].isNotEmpty ? parts[1] : null,
            username: parts[2],
            password: parts[3],
            notes: parts.length > 4 ? parts[4] : null,
            category: '其他',
          );
          await _db.insertPassword(entry);
        }
      }

      return true;
    } catch (e) {
      print('CSV import error: $e');
      return false;
    }
  }

  /// 获取导出目录
  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// 转义 CSV 字段
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// 解析 CSV 行
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // 跳过下一个引号
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    
    result.add(current.toString());
    return result;
  }
}