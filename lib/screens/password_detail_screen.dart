import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import 'add_password_screen.dart';

/// 密码详情页面
class PasswordDetailScreen extends StatelessWidget {
  final PasswordEntry entry;

  const PasswordDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Text(
          entry.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPasswordScreen(entry: entry),
                ),
              );
              if (context.mounted) {
                Navigator.pop(context); // 返回后刷新
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标和大标题
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        entry.title.isNotEmpty
                            ? entry.title[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.category,
                      style: TextStyle(
                        color: _getCategoryColor(entry.category),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 信息卡片
            _buildInfoCard(
              title: '账号',
              value: entry.username,
              icon: Icons.person,
              onCopy: () => _copyToClipboard(context, entry.username, '账号'),
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              title: '密码',
              value: entry.password,
              icon: Icons.lock,
              isPassword: true,
              onCopy: () => _copyToClipboard(context, entry.password, '密码'),
            ),

            if (entry.url != null && entry.url!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '网址',
                value: entry.url!,
                icon: Icons.link,
                onCopy: () => _copyToClipboard(context, entry.url!, '网址'),
                onOpen: () {
                  // 打开网址
                },
              ),
            ],

            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                title: '备注',
                value: entry.notes!,
                icon: Icons.note,
                onCopy: () => _copyToClipboard(context, entry.notes!, '备注'),
              ),
            ],

            const SizedBox(height: 32),

            // 时间信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTimeRow('创建时间', entry.createdAt),
                  const Divider(color: Colors.white10, height: 24),
                  _buildTimeRow('最后修改', entry.updatedAt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onCopy,
    VoidCallback? onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onOpen != null)
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.amber,
                      ),
                      onPressed: onOpen,
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber),
                    onPressed: onCopy,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        Text(
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type已复制到剪贴板'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 如果是密码，30秒后清除
    if (type == '密码') {
      Future.delayed(const Duration(seconds: 30), () {
        Clipboard.setData(const ClipboardData(text: ''));
      });
    }
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
}