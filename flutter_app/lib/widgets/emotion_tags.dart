import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// 情绪标签选择器
class EmotionTagsSelector extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChange;
  final int maxTags;
  final bool enabled;

  const EmotionTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChange,
    this.maxTags = 3,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canSelectMore = selectedTags.length < maxTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '选择情感标签 (最多$maxTags个)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selectedTags.isNotEmpty)
              Text(
                '已选 ${selectedTags.length}/$maxTags',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.lovePink,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionTags.tags.map((tag) {
            final isSelected = selectedTags.contains(tag.id);
            final canSelect = canSelectMore || isSelected;

            return _EmotionTagChip(
              tag: tag,
              isSelected: isSelected,
              enabled: enabled && canSelect,
              onTap: enabled && canSelect
                  ? () => _toggleTag(tag.id)
                  : null,
            );
          }).toList(),
        ),
        if (selectedTags.length == maxTags)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '💡 已达到最大标签数量，取消选择一个标签后可选择其他标签',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade700,
              ),
            ),
          ),
      ],
    );
  }

  void _toggleTag(String tagId) {
    final newTags = List<String>.from(selectedTags);
    if (newTags.contains(tagId)) {
      newTags.remove(tagId);
    } else {
      newTags.add(tagId);
    }
    onTagsChange(newTags);
  }
}

/// 情绪标签芯片
class _EmotionTagChip extends StatelessWidget {
  final EmotionTag tag;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _EmotionTagChip({
    required this.tag,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tag.color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? tag.color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              tag.label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 情绪标签显示组件
class EmotionTagsDisplay extends StatelessWidget {
  final List<String> tags;
  final int maxDisplay;

  const EmotionTagsDisplay({
    super.key,
    required this.tags,
    this.maxDisplay = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final displayTags = tags.take(maxDisplay).toList();
    final remainingCount = tags.length - maxDisplay;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTags.map((tagId) {
          final tag = EmotionTags.getById(tagId);
          if (tag == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tag.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tag.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  tag.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: tag.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
