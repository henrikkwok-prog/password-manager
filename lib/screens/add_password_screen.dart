import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

/// 添加/编辑密码页面
class AddPasswordScreen extends StatefulWidget {
  final PasswordEntry? entry; // 如果传入则为编辑模式

  const AddPasswordScreen({super.key, this.entry});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '其他';
  bool _showPassword = false;
  int _passwordStrength = 0;

  final List<String> _categories = [
    '社交',
    '银行',
    '购物',
    '工作',
    '邮箱',
    '游戏',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      // 编辑模式：填充数据
      _titleController.text = widget.entry!.title;
      _usernameController.text = widget.entry!.username;
      _passwordController.text = widget.entry!.password;
      _urlController.text = widget.entry!.url ?? '';
      _notesController.text = widget.entry!.notes ?? '';
      _selectedCategory = widget.entry!.category;
      _updatePasswordStrength();
    }
  }

  void _updatePasswordStrength() {
    final strength = EncryptionService().calculatePasswordStrength(
      _passwordController.text,
    );
    setState(() {
      _passwordStrength = strength;
    });
  }

  void _generatePassword() {
    final password = EncryptionService().generatePassword(
      length: 16,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSpecial: true,
    );
    _passwordController.text = password;
    _updatePasswordStrength();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = PasswordEntry(
      id: widget.entry?.id,
      title: _titleController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      url: _urlController.text.isEmpty ? null : _urlController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      category: _selectedCategory,
    );

    final db = DatabaseService();
    if (widget.entry != null) {
      await db.updatePassword(entry);
    } else {
      await db.insertPassword(entry);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Text(
          isEdit ? '编辑密码' : '添加密码',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            _buildTextField(
              controller: _titleController,
              label: '网站/应用名称',
              hint: '例如：微信、淘宝、Gmail',
              icon: Icons.web,
              validator: (value) => value?.isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),

            // 分类选择
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 账号
            _buildTextField(
              controller: _usernameController,
              label: '账号/用户名',
              hint: '请输入账号',
              icon: Icons.person,
              validator: (value) => value?.isEmpty == true ? '请输入账号' : null,
            ),
            const SizedBox(height: 16),

            // 密码
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_showPassword,
                    onChanged: (_) => _updatePasswordStrength(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '请输入密码',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.amber),
                            onPressed: _generatePassword,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? '请输入密码' : null,
                  ),
                  // 密码强度指示器
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength / 100,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation(
                                    _getStrengthColor(_passwordStrength),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getStrengthText(_passwordStrength),
                              style: TextStyle(
                                color: _getStrengthColor(_passwordStrength),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // URL
            _buildTextField(
              controller: _urlController,
              label: '网址（可选）',
              hint: 'https://...',
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // 备注
            _buildTextField(
              controller: _notesController,
              label: '备注（可选）',
              hint: '添加备注信息...',
              icon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEdit ? '保存修改' : '添加密码',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      '社交': Icons.people,
      '银行': Icons.account_balance,
      '购物': Icons.shopping_cart,
      '工作': Icons.work,
      '邮箱': Icons.email,
      '游戏': Icons.games,
      '其他': Icons.category,
    };
    return icons[category] ?? Icons.category;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      '社交': Colors.blue,
      '银行': Colors.green,
      '购物': Colors.orange,
      '工作': Colors.purple,
      '邮箱': Colors.red,
      '游戏': Colors.pink,
      '其他': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  Color _getStrengthColor(int strength) {
    if (strength < 30) return Colors.red;
    if (strength < 60) return Colors.orange;
    if (strength < 80) return Colors.yellow;
    return Colors.green;
  }

  String _getStrengthText(int strength) {
    if (strength < 30) return '弱';
    if (strength < 60) return '一般';
    if (strength < 80) return '良好';
    return '强';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}