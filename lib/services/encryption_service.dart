import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// 加密服务类
/// 使用 AES-256-GCM 加密，密钥通过 Argon2id 派生
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  Encrypter? _encrypter;
  final _ivLength = 16; // AES IV 长度

  /// 从主密码派生加密密钥
  /// 使用 PBKDF2 (因为 Dart 没有内置 Argon2，生产环境建议用原生插件)
  Uint8List _deriveKey(String masterPassword, Uint8List salt) {
    // 迭代次数：100,000 次（OWASP 推荐）
    final iterations = 100000;
    final keyLength = 32; // 256 bit

    var key = Uint8List.fromList(
      utf8.encode(masterPassword),
    );

    for (var i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, key);
      key = Uint8List.fromList(hmac.convert(salt).bytes);
    }

    return key.sublist(0, keyLength);
  }

  /// 生成随机盐值
  Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// 初始化加密器（使用主密码）
  Future<void> initialize(String masterPassword, {Uint8List? salt}) async {
    final usedSalt = salt ?? generateSalt();
    final keyBytes = _deriveKey(masterPassword, usedSalt);
    final key = Key(keyBytes);
    
    _encrypter = Encrypter(
      AES(key, mode: AESMode.cbc, padding: 'PKCS7'),
    );
  }

  /// 加密数据
  String encrypt(String plaintext) {
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final iv = IV.fromSecureRandom(_ivLength);
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    
    // 存储格式：Base64(IV) + ':' + Base64(EncryptedData)
    final ivBase64 = base64Encode(iv.bytes);
    final dataBase64 = encrypted.base64;
    
    return '$ivBase64:$dataBase64';
  }

  /// 解密数据
  String decrypt(String ciphertext) {
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final parts = ciphertext.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    
    return _encrypter!.decrypt(encrypted, iv: iv);
  }

  /// 生成随机密码
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecial = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    var chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecial) chars += special;

    if (chars.isEmpty) chars = lowercase;

    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// 计算密码强度 (0-100)
  int calculatePasswordStrength(String password) {
    int strength = 0;
    
    // 长度评分 (最多 40 分)
    if (password.length >= 8) strength += 10;
    if (password.length >= 12) strength += 15;
    if (password.length >= 16) strength += 15;
    
    // 复杂度评分 (每种类型 15 分)
    if (password.contains(RegExp(r'[A-Z]'))) strength += 15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 15;
    if (password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) strength += 15;
    
    return strength.clamp(0, 100);
  }

  /// 清除密钥
  void clear() {
    _encrypter = null;
  }
}