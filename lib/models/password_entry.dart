import 'dart:convert';

/// 密码条目模型
class PasswordEntry {
  final String? id;
  final String title;        // 网站/APP名称
  final String username;     // 账号
  final String password;     // 密码（加密存储）
  final String? url;         // 网站URL
  final String? notes;       // 备注
  final String category;     // 分类
  final List<String> tags;   // 标签
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> passwordHistory; // 历史密码

  PasswordEntry({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.category = '其他',
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.passwordHistory = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'url': url,
      'notes': notes,
      'category': category,
      'tags': jsonEncode(tags),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'passwordHistory': jsonEncode(passwordHistory),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      url: map['url'],
      notes: map['notes'],
      category: map['category'] ?? '其他',
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      passwordHistory: List<String>.from(
        jsonDecode(map['passwordHistory'] ?? '[]'),
      ),
    );
  }

  PasswordEntry copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? passwordHistory,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      passwordHistory: passwordHistory ?? this.passwordHistory,
    );
  }
}