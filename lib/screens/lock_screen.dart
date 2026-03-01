import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/encryption_service.dart';

/// 锁屏/登录页面
class LockScreen extends StatefulWidget {
  final bool isFirstLaunch;
  final VoidCallback onAuthenticated;

  const LockScreen({
    super.key,
    required this.isFirstLaunch,
    required this.onAuthenticated,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _showPassword = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstLaunch) {
      _tryBiometricAuth();
    }
  }

  /// 尝试生物识别认证
  Future<void> _tryBiometricAuth() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) return;

      final result = await _localAuth.authenticate(
        localizedReason: '请验证身份以解锁密码管理器',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (result && mounted) {
        // 生物识别成功后，需要从安全存储读取主密码
        // TODO: 实现从 Keychain/Keystore 读取
        widget.onAuthenticated();
      }
    } catch (e) {
      print('Biometric error: $e');
    }
  }

  /// 设置主密码（首次启动）
  Future<void> _setupMasterPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '请输入主密码';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = '主密码至少需要8位';
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = '两次输入的密码不一致';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 初始化加密服务
      await EncryptionService().initialize(_passwordController.text);
      
      // TODO: 保存主密码到安全存储
      
      if (mounted) {
        widget.onAuthenticated();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '设置失败，请重试';
        _isLoading = false;
      });
    }
  }

  /// 验证主密码
  Future<void> _verifyMasterPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '请输入主密码';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // TODO: 验证主密码
      // 这里应该尝试解密一个测试数据来验证密码是否正确
      
      await EncryptionService().initialize(_passwordController.text);
      
      if (mounted) {
        widget.onAuthenticated();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '密码错误';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 50,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),

              // 标题
              Text(
                widget.isFirstLaunch ? '设置主密码' : '欢迎回来',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isFirstLaunch
                    ? '请设置一个安全的主密码\n用于加密您的所有密码'
                    : '请输入主密码解锁',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // 密码输入
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '输入主密码',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 确认密码（仅首次启动）
              if (widget.isFirstLaunch) ...[
                TextField(
                  controller: _confirmController,
                  obscureText: !_showPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '确认主密码',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 错误信息
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              // 按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : widget.isFirstLaunch
                          ? _setupMasterPassword
                          : _verifyMasterPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : Text(
                          widget.isFirstLaunch ? '设置并进入' : '解锁',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 生物识别按钮（非首次启动）
              if (!widget.isFirstLaunch)
                TextButton.icon(
                  onPressed: _tryBiometricAuth,
                  icon: const Icon(Icons.fingerprint, color: Colors.amber),
                  label: const Text(
                    '使用指纹/面容解锁',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),

              // 提示
              if (widget.isFirstLaunch)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    '⚠️ 请务必牢记主密码\n丢失将无法恢复您的数据',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}