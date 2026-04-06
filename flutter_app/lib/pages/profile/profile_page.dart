import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/storage_info.dart';
import '../../widgets/bottom_navigation.dart';

/// 个人中心页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final coupleAsync = ref.watch(currentCoupleProvider);
    final hasCouple = ref.watch(hasCoupleProvider);
    final partner = ref.watch(partnerProvider);

    return Scaffold(
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/records');
            case 2:
              context.go('/gallery');
            case 3:
              context.go('/profile');
          }
        },
      ),
      body: CustomScrollView(
        slivers: [
          // 顶部渐变背景
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      '我的',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: userAsync.when(
              data: (user) {
                if (user == null) {
                  return const SizedBox.shrink();
                }
                return _buildContent(context, ref, user, coupleAsync, hasCouple, partner);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('加载失败'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    user,
    coupleAsync,
    bool hasCouple,
    ({String? name, String? email}) partner,
  ) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 用户信息卡片
          _buildUserCard(context, user),

          const SizedBox(height: 16),

          // 情侣空间卡片
          if (hasCouple) _buildCoupleCard(context, coupleAsync, partner),

          const SizedBox(height: 16),

          // 存储空间
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StorageInfoBar(
              usedStorage: user.usedStorage,
              isVip: user.isVip,
            ),
          ),

          const SizedBox(height: 16),

          // 快捷入口
          _buildQuickActions(context, hasCouple),

          const SizedBox(height: 16),

          // 设置和退出
          _buildSettingsAndLogout(context, ref, user, hasCouple),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 用户信息卡片
  Widget _buildUserCard(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 情侣空间卡片
  Widget _buildCoupleCard(
    BuildContext context,
    coupleAsync,
    ({String? name, String? email}) partner,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppTheme.lovePink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '情侣空间',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          coupleAsync.when(
            data: (couple) {
              if (couple == null) return const SizedBox.shrink();
              return Column(
                children: [
                  _buildInfoRow('空间名称', couple.coupleName),
                  if (partner.name != null) _buildInfoRow('伴侣', partner.name!),
                  if (couple.anniversaryDate != null)
                    _buildInfoRow(
                      '纪念日',
                      _formatDate(couple.anniversaryDate!),
                    ),
                  _buildInviteCodeRow(context, couple.inviteCode),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildInviteCodeRow(BuildContext context, String inviteCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '邀请码',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Row(
            children: [
              Text(
                inviteCode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lovePink,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.copy, size: 18),
                onPressed: () => _copyInviteCode(context, inviteCode),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 快捷入口
  Widget _buildQuickActions(BuildContext context, bool hasCouple) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '快速访问',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _buildActionItem(
            context,
            icon: Icons.format_list_bulleted,
            iconColor: AppTheme.lovePurple,
            title: '愿望清单',
            onTap: () => context.push('/wishlists'),
          ),
          if (!hasCouple)
            _buildActionItem(
              context,
              icon: Icons.group_add,
              iconColor: AppTheme.lovePink,
              title: '创建情侣空间',
              onTap: () => context.push('/couple-setup/create'),
            ),
          if (hasCouple)
            _buildActionItem(
              context,
              icon: Icons.favorite,
              iconColor: AppTheme.lovePink,
              title: '管理情侣空间',
              onTap: () => context.push('/settings'),
            ),
        ],
      ),
    );
  }

  // 设置和退出
  Widget _buildSettingsAndLogout(
    BuildContext context,
    WidgetRef ref,
    user,
    bool hasCouple,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          _buildActionItem(
            context,
            icon: Icons.settings_outlined,
            iconColor: AppTheme.textSecondary,
            title: '设置',
            onTap: () => context.push('/settings'),
          ),
          Divider(height: 1, color: AppTheme.divider),
          _buildActionItem(
            context,
            icon: Icons.logout,
            iconColor: AppTheme.error,
            title: '退出登录',
            titleColor: AppTheme.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: titleColor ?? AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _copyInviteCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('邀请码已复制'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(currentUserProvider.notifier).logout();
            },
            child: Text(
              '退出',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
