import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/record.dart';
import '../../providers/couple_provider.dart';
import '../../providers/record_provider.dart';
import '../../widgets/bottom_navigation.dart';

/// 首页 - 仪表盘
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider);
    final recordsAsync = ref.watch(recordListProvider);
    final statsAsync = ref.watch(recordStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            _buildAppBar(context),
            // 主内容区域
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(currentCoupleProvider.notifier).refresh();
                  await ref.read(recordListProvider.notifier).refresh();
                },
                color: AppTheme.lovePink,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: coupleAsync.when(
                    data: (couple) {
                      if (couple == null) {
                        return _buildLoadingState();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 欢迎横幅
                          _buildWelcomeBanner(context, couple),
                          const SizedBox(height: 20),

                          // 快捷操作
                          _buildQuickActions(context),
                          const SizedBox(height: 24),

                          // 最近约会
                          _buildRecentSection(context, recordsAsync),
                          const SizedBox(height: 16),

                          // 月度统计
                          _buildMonthlyStats(context, statsAsync),
                        ],
                      );
                    },
                    loading: () => _buildLoadingState(),
                    error: (_, __) => _buildErrorState(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/records');
              break;
            case 2:
              context.go('/gallery');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.favorite, color: AppTheme.lovePink, size: 24),
          const SizedBox(width: 8),
          Text(
            'Love4Lili',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              // TODO: 实现通知
            },
          ),
        ],
      ),
    );
  }

  /// 欢迎横幅
  Widget _buildWelcomeBanner(BuildContext context, couple) {
    final daysTogether = couple.anniversaryDate != null
        ? DateTime.now().difference(couple.anniversaryDate!).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      couple.coupleName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  couple.isComplete ? '甜蜜恋爱中' : '等待伴侣加入...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                if (daysTogether > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '在一起 ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '$daysTogether',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        ' 天',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.white.withOpacity(0.9),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 快捷操作按钮
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.edit_note,
        label: '记录约会',
        color: AppTheme.lovePink,
        route: '/records/new',
      ),
      _QuickAction(
        icon: Icons.card_giftcard,
        label: '愿望清单',
        color: AppTheme.lovePurple,
        route: '/wishlists',
      ),
      _QuickAction(
        icon: Icons.photo_library,
        label: '相册',
        color: AppTheme.lovePink,
        route: '/gallery',
        isGradient: true,
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: actions.indexOf(action) < actions.length - 1 ? 12 : 0,
            ),
            child: _QuickActionButton(
              action: action,
              onTap: () => context.go(action.route),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 最近约会区域
  Widget _buildRecentSection(BuildContext context, AsyncValue<List<DatingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context);
        }

        final recentRecords = records.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近约会',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/records'),
                  child: Text(
                    '查看全部',
                    style: TextStyle(
                      color: AppTheme.lovePink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentRecords.map((record) => _RecordCard(
              record: record,
              onTap: () => context.go('/records/${record.id}'),
            )),
          ],
        );
      },
      loading: () => _buildRecentSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.loveLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              color: AppTheme.lovePink,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有约会记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '记录第一次约会，开始美好回忆',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/records/new'),
            icon: const Icon(Icons.add),
            label: const Text('记录第一次约会'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lovePink,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 月度统计
  Widget _buildMonthlyStats(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final monthlyCount = stats['monthly_count'] ?? 0;
        final moodDistribution = stats['mood_distribution'] is Map
            ? stats['mood_distribution'] as Map<String, dynamic>
            : <String, dynamic>{};

        if (monthlyCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.green.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月统计',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '本月共 $monthlyCount 次约会',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 心情分布
              if (moodDistribution.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: moodDistribution.entries.take(4).map((entry) {
                    final moodOption = MoodOptions.options[entry.key];
                    if (moodOption == null) return const SizedBox.shrink();
                    return Text(
                      moodOption.emoji,
                      style: const TextStyle(fontSize: 16),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
      loading: () => _buildStatsSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildBannerSkeleton(),
        const SizedBox(height: 20),
        _buildQuickActionsSkeleton(),
        const SizedBox(height: 24),
        _buildRecentSkeleton(),
      ],
    );
  }

  /// 错误状态
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查网络连接后重试',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(currentCoupleProvider.notifier).refresh();
                ref.read(recordListProvider.notifier).refresh();
              },
              child: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  /// 横幅骨架屏
  Widget _buildBannerSkeleton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: _Shimmer(),
    );
  }

  /// 快捷操作骨架屏
  Widget _buildQuickActionsSkeleton() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: _Shimmer(),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _Shimmer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 最近记录骨架屏
  Widget _buildRecentSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _Shimmer(),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: _Shimmer(),
          ),
        )),
      ],
    );
  }

  /// 统计骨架屏
  Widget _buildStatsSkeleton() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: _Shimmer(),
    );
  }
}

/// 快捷操作数据模型
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool isGradient;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.isGradient = false,
  });
}

/// 快捷操作按钮
class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: action.isGradient ? AppTheme.primaryGradient : null,
              color: action.isGradient ? null : action.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              action.icon,
              color: action.isGradient ? Colors.white : action.color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 记录卡片
class _RecordCard extends StatelessWidget {
  final DatingRecord record;
  final VoidCallback onTap;

  const _RecordCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final moodOption = MoodOptions.options[record.mood];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(record.recordDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (record.location != null && record.location!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            record.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 情绪标签
                  if (record.emotionTags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: record.emotionTags.take(3).map((tagId) {
                        final tag = EmotionTags.getById(tagId);
                        if (tag == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tag.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // 右侧心情
            if (moodOption != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: moodOption.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  moodOption.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}

/// 骨架屏闪烁效果
class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}
