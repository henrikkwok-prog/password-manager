import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // 安全设置
          _buildSectionTitle('安全'),
          _buildSettingItem(
            icon: Icons.fingerprint,
            title: '生物识别',
            subtitle: '使用指纹/面容快速解锁',
            trailing: Switch(
              value: true, // TODO: 读取实际设置
              onChanged: (value) {},
              activeColor: Colors.amber,
            ),
          ),
          _buildSettingItem(
            icon: Icons.timer,
            title: '自动锁定',
            subtitle: '离开应用后自动锁定',
            onTap: () => _showAutoLockDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.visibility_off,
            title: '隐藏密码',
            subtitle: '在列表中隐藏密码内容',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.amber,
            ),
          ),

          // 备份与恢复
          _buildSectionTitle('备份与恢复'),
          _buildSettingItem(
            icon: Icons.backup,
            title: '导出备份',
            subtitle: '导出加密备份文件',
            onTap: () => _exportBackup(context),
          ),
          _buildSettingItem(
            icon: Icons.restore,
            title: '导入备份',
            subtitle: '从备份文件恢复',
            onTap: () => _importBackup(context),
          ),
          _buildSettingItem(
            icon: Icons.file_download,
            title: '导出为 CSV',
            subtitle: '导出为通用格式（明文，谨慎使用）',
            onTap: () => _exportCSV(context),
          ),
          _buildSettingItem(
            icon: Icons.file_upload,
            title: '从 CSV 导入',
            subtitle: '从其他密码管理器导入',
            onTap: () => _importCSV(context),
          ),

          // 其他
          _buildSectionTitle('其他'),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: '深色模式',
            subtitle: '跟随系统',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Colors.amber,
            ),
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: '语言',
            subtitle: '简体中文',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.info,
            title: '关于',
            subtitle: '版本 1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // 危险区域
          _buildSectionTitle('危险区域', color: Colors.red),
          _buildSettingItem(
            icon: Icons.delete_forever,
            title: '清除所有数据',
            subtitle: '删除所有密码和设置（不可恢复）',
            textColor: Colors.red,
            onTap: () => _showClearDataDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.logout,
            title: '退出登录',
            subtitle: '退出当前账号',
            textColor: Colors.orange,
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.white54)
              : null),
      onTap: onTap,
    );
  }

  /// 导出备份
  Future<void> _exportBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '导出备份',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '备份文件将包含您的所有密码，请妥善保管。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final path = await BackupService().exportBackup();

    if (context.mounted) {
      Navigator.pop(context);
      
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份已导出: $path')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败')),
        );
      }
    }
  }

  /// 导入备份
  Future<void> _importBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '导入备份',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '导入将合并现有数据，如有重复可能会覆盖。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await BackupService().importBackup();

    if (context.mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '导入成功' : '导入失败'),
        ),
      );
    }
  }

  /// 导出 CSV
  Future<void> _exportCSV(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '⚠️ 安全警告',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Text(
          'CSV 格式不包含加密，密码将以明文形式存储。\n\n请确保文件传输和存储环境安全，使用后立即删除。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('仍要导出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final path = await BackupService().exportToCSV();
    
    if (context.mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV 已导出: $path')),
      );
    }
  }

  /// 导入 CSV
  Future<void> _importCSV(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await BackupService().importFromCSV();

    if (context.mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '导入成功' : '导入失败'),
        ),
      );
    }
  }

  /// 自动锁定设置
  void _showAutoLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '自动锁定',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLockOption(context, '立即', 0),
            _buildLockOption(context, '30 秒', 30),
            _buildLockOption(context, '1 分钟', 60),
            _buildLockOption(context, '5 分钟', 300),
            _buildLockOption(context, '从不', -1),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOption(BuildContext context, String label, int seconds) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: seconds == 60
          ? const Icon(Icons.check, color: Colors.amber)
          : null,
      onTap: () {
        // TODO: 保存设置
        Navigator.pop(context);
      },
    );
  }

  /// 清除数据确认
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '⚠️ 危险操作',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          '此操作将永久删除所有密码数据，无法恢复。\n\n请输入 "DELETE" 确认：',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().clearDatabase();
              if (context.mounted) {
                Navigator.pop(context);
                // TODO: 退出到登录页
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  /// 退出登录确认
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '退出登录',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '退出后将需要重新输入主密码才能访问。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              EncryptionService().clear();
              Navigator.pop(context);
              // TODO: 退出到登录页
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}