import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/storage_info.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final coupleAsync = ref.watch(currentCoupleProvider);
    final hasCouple = ref.watch(hasCoupleProvider);
    final partner = ref.watch(partnerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('设置'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          // 初始化名字控制器
          if (_nameController.text != user.name) {
            _nameController.text = user.name;
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // 个人资料 Section
                _buildSection(
                  title: '个人资料',
                  child: _buildProfileSection(user),
                ),

                // 情侣空间 Section
                if (hasCouple)
                  _buildSection(
                    title: '情侣空间',
                    child: _buildCoupleSection(coupleAsync, partner),
                  ),

                // 存储管理 Section
                _buildSection(
                  title: '存储管理',
                  child: _buildStorageSection(user),
                ),

                // 关于 Section
                _buildSection(
                  title: '关于',
                  child: _buildAboutSection(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('加载失败')),
      ),
    );
  }

  // Section 容器
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: child,
        ),
      ],
    );
  }

  // 个人资料 Section
  Widget _buildProfileSection(user) {
    if (_isEditingName) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: AppTheme.lovePink),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '输入昵称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _updateProfileName(),
              child: Text('保存'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingName = false;
                  _nameController.text = user.name;
                });
              },
              child: Text('取消'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildListTile(
          icon: Icons.person_outline,
          iconColor: AppTheme.lovePink,
          title: '修改昵称',
          trailing: Text(
            user.name,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          onTap: () {
            setState(() {
              _isEditingName = true;
              _nameController.text = user.name;
            });
          },
        ),
        _buildListTile(
          icon: Icons.email_outlined,
          iconColor: AppTheme.textSecondary,
          title: '邮箱',
          trailing: Text(
            user.email,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          onTap: null,
        ),
        if (user.isVip)
          _buildListTile(
            icon: Icons.workspace_premium,
            iconColor: Colors.amber,
            title: 'VIP 状态',
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VIP',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: null,
          ),
      ],
    );
  }

  // 情侣空间 Section
  Widget _buildCoupleSection(coupleAsync, partner) {
    return coupleAsync.when(
      data: (couple) {
        if (couple == null) return const SizedBox.shrink();
        return Column(
          children: [
            _buildListTile(
              icon: Icons.favorite_border,
              iconColor: AppTheme.lovePink,
              title: '情侣名称',
              trailing: Text(
                couple.coupleName,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              onTap: () => _showEditCoupleNameDialog(couple),
            ),
            if (couple.anniversaryDate != null)
              _buildListTile(
                icon: Icons.cake_outlined,
                iconColor: AppTheme.lovePurple,
                title: '纪念日',
                trailing: Text(
                  _formatDate(couple.anniversaryDate!),
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                onTap: () => _showEditAnniversaryDialog(couple),
              ),
            _buildListTile(
              icon: Icons.copy,
              iconColor: AppTheme.textSecondary,
              title: '邀请码',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    couple.inviteCode,
                    style: TextStyle(
                      color: AppTheme.lovePink,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
                ],
              ),
              onTap: () => _copyInviteCode(couple.inviteCode),
            ),
            Divider(height: 1, color: AppTheme.divider, indent: 48),
            _buildListTile(
              icon: Icons.link_off,
              iconColor: AppTheme.error,
              title: '解除关系',
              titleColor: AppTheme.error,
              trailing: Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.error,
              ),
              onTap: () => _showBreakUpDialog(),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // 存储管理 Section
  Widget _buildStorageSection(user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 存储条
          StorageInfoBar(
            usedStorage: user.usedStorage,
            isVip: user.isVip,
          ),
          const SizedBox(height: 16),

          // 存储详情
          Text(
            '存储限制',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStorageDetailRow('单张照片最大', user.isVip ? '20 MB' : '10 MB'),
          _buildStorageDetailRow('单个视频最大', user.isVip ? '200 MB' : '100 MB'),
          _buildStorageDetailRow(
            '总存储空间',
            user.isVip ? '1 GB' : '100 MB',
          ),
        ],
      ),
    );
  }

  Widget _buildStorageDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 关于 Section
  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.info_outline,
          iconColor: AppTheme.textSecondary,
          title: '版本',
          trailing: Text(
            '1.0.0',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          onTap: null,
        ),
        _buildListTile(
          icon: Icons.description_outlined,
          iconColor: AppTheme.textSecondary,
          title: '隐私政策',
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTheme.textHint,
          ),
          onTap: () {
            // TODO: 打开隐私政策页面
          },
        ),
        _buildListTile(
          icon: Icons.help_outline,
          iconColor: AppTheme.textSecondary,
          title: '帮助与反馈',
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTheme.textHint,
          ),
          onTap: () {
            // TODO: 打开帮助页面
          },
        ),
      ],
    );
  }

  // 通用 ListTile 样式
  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  // 更新昵称
  Future<void> _updateProfileName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('昵称不能为空')),
      );
      return;
    }

    try {
      await ref.read(currentUserProvider.notifier).updateProfile(name: name);
      setState(() {
        _isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('昵称更新成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  // 修改情侣名称
  void _showEditCoupleNameDialog(couple) {
    final controller = TextEditingController(text: couple.coupleName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改情侣名称'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入情侣名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('名称不能为空')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await ref
                    .read(currentCoupleProvider.notifier)
                    .updateCouple(coupleName: name);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('情侣名称更新成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新失败: $e')),
                  );
                }
              }
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  // 修改纪念日
  void _showEditAnniversaryDialog(couple) {
    DateTime selectedDate = couple.anniversaryDate ?? DateTime.now();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改纪念日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择日期'),
            const SizedBox(height: 16),
            // 简化版，实际应使用日期选择器
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: Text(_formatDate(selectedDate)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(currentCoupleProvider.notifier)
                    .updateCouple(anniversaryDate: selectedDate);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('纪念日更新成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新失败: $e')),
                  );
                }
              }
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  // 复制邀请码
  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('邀请码已复制'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 解除关系确认
  void _showBreakUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '解除关系',
          style: TextStyle(color: AppTheme.error),
        ),
        content: Text('确定要解除情侣关系吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(currentCoupleProvider.notifier).deleteCouple();
                if (mounted) {
                  Navigator.pop(context); // 返回上一页
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已解除情侣关系')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失败: $e')),
                  );
                }
              }
            },
            child: Text(
              '确定解除',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
