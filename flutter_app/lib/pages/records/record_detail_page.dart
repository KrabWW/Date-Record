import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/record.dart';
import '../../providers/record_provider.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/emotion_tags.dart';
import '../../models/media.dart';

/// 记录详情页面
class RecordDetailPage extends ConsumerStatefulWidget {
  const RecordDetailPage({super.key});

  @override
  ConsumerState<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends ConsumerState<RecordDetailPage> {
  @override
  Widget build(BuildContext context) {
    final idStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final id = int.tryParse(idStr) ?? 0;
    final recordAsync = ref.watch(currentRecordProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: recordAsync.hasValue
                ? () => context.go('/records/$id/edit')
                : null,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => _DeleteConfirmDialog(record: recordAsync.value),
                );
                if (confirmed == true && mounted) {
                  await ref.read(currentRecordProvider(id).notifier).deleteRecord();
                  if (mounted) context.go('/records');
                }
              } else if (value == 'edit') {
                context.go('/records/$id/edit');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('编辑'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppTheme.error),
                    SizedBox(width: 12),
                    Text('删除', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return _buildNotFound();
          }
          return _buildContent(record);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => _buildError(),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '记录不存在',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/records'),
            child: const Text('返回列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/records'),
            child: const Text('返回列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DatingRecord record) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 照片轮播
          if (record.photos.isNotEmpty) _buildPhotoCarousel(record.photos),
          if (record.photos.isNotEmpty) const SizedBox(height: 24),

          // 标题
          Text(
            record.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 日期和地点
          _buildMetaInfo(record),
          const SizedBox(height: 16),

          // 心情
          _buildMoodSection(record.mood),
          const SizedBox(height: 16),

          // 情绪标签
          if (record.emotionTags.isNotEmpty) ...[
            _buildEmotionTagsSection(record.emotionTags),
            const SizedBox(height: 16),
          ],

          // 描述
          if (record.description != null && record.description!.isNotEmpty) ...[
            _buildDescriptionSection(record.description!),
            const SizedBox(height: 16),
          ],

          // 自定义标签
          if (record.tags.isNotEmpty) ...[
            _buildTagsSection(record.tags),
            const SizedBox(height: 16),
          ],

          // 底部操作按钮
          _buildActionButtons(record.id),
          const SizedBox(height: 24),

          // 创建时间
          _buildTimestampInfo(record),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(List<Media> photos) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Image.network(
              photo.fileUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaInfo(DatingRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          // 日期
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lovePink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.lovePink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatFullDate(record.recordDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (record.location != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // 地点
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lovePurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.lovePurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.location!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodSection(String mood) {
    final moodOption = MoodOptions.options[mood];
    if (moodOption == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodOption.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: moodOption.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            moodOption.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '当时的心情',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                moodOption.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: moodOption.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTagsSection(List<String> emotionTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.tag,
              size: 20,
              color: AppTheme.lovePink,
            ),
            SizedBox(width: 8),
            Text(
              '情感标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        EmotionTagsDisplay(tags: emotionTags, maxDisplay: 10),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.description,
              size: 20,
              color: AppTheme.lovePink,
            ),
            SizedBox(width: 8),
            Text(
              '详细描述',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.local_offer,
              size: 20,
              color: AppTheme.lovePink,
            ),
            SizedBox(width: 8),
            Text(
              '标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: AppTheme.lovePink.withOpacity(0.1),
              labelStyle: const TextStyle(
                color: AppTheme.lovePink,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(int recordId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/records/$recordId/edit'),
            icon: const Icon(Icons.edit),
            label: const Text('编辑'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除记录'),
                  content: const Text('确定要删除这条记录吗？此操作无法撤销。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await ref.read(currentRecordProvider(recordId).notifier).deleteRecord();
                if (mounted) context.go('/records');
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('删除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampInfo(DatingRecord record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '创建于 ${_formatDateTime(record.createdAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          if (record.updatedAt.isAfter(record.createdAt.add(const Duration(seconds: 1)))) ...[
            const SizedBox(height: 4),
            Text(
              '更新于 ${_formatDateTime(record.updatedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const months = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
    ];
    return '${date.year}年${months[date.month - 1]}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 删除确认对话框
class _DeleteConfirmDialog extends StatelessWidget {
  final DatingRecord? record;

  const _DeleteConfirmDialog({required this.record});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('确定要删除这条记录吗？此操作无法撤销。'),
          if (record != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record!.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.error,
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
