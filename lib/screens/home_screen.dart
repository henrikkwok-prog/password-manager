import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import 'add_password_screen.dart';
import 'password_detail_screen.dart';

/// 主页 Provider
final passwordListProvider = FutureProvider.autoDispose
    <List<PasswordEntry>>((ref) async {
  final db = DatabaseService();
  return await db.getAllPasswords();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

/// 主页
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordsAsync = ref.watch(passwordListProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text(
          '密码管理器',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              // 打开设置页面
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '搜索密码...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // 密码列表
          Expanded(
            child: passwordsAsync.when(
              data: (passwords) {
                // 搜索过滤
                final filtered = searchQuery.isEmpty
                    ? passwords
                    : passwords
                        .where((p) =>
                            p.title.toLowerCase().contains(
                                searchQuery.toLowerCase()) ||
                            p.username.toLowerCase().contains(
                                searchQuery.toLowerCase()) ||
                            (p.url?.toLowerCase().contains(
                                    searchQuery.toLowerCase()) ??
                                false))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isEmpty
                              ? Icons.lock_outline
                              : Icons.search_off,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? '还没有保存的密码\n点击右下角添加'
                              : '没有找到匹配的密码',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _PasswordCard(
                      entry: entry,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PasswordDetailScreen(
                              entry: entry,
                            ),
                          ),
                        );
                        // 刷新列表
                        ref.invalidate(passwordListProvider);
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF16213E),
                            title: const Text(
                              '确认删除',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              '确定要删除 "${entry.title}" 吗？',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await DatabaseService().deletePassword(
                            int.parse(entry.id!),
                          );
                          ref.invalidate(passwordListProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  '加载失败: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
          );
          ref.invalidate(passwordListProvider);
        },
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          '添加密码',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 密码卡片
class _PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PasswordCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFF16213E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(entry.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                entry.title.isNotEmpty
                    ? entry.title[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            entry.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                entry.username,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.category,
                  style: TextStyle(
                    color: _getCategoryColor(entry.category),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: entry.password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('密码已复制到剪贴板（30秒后清除）'),
                  duration: Duration(seconds: 2),
                ),
              );
              // 30秒后清除剪贴板
              Future.delayed(const Duration(seconds: 30), () {
                Clipboard.setData(const ClipboardData(text: ''));
              });
            },
          ),
          onTap: onTap,
        ),
      ),
    );
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