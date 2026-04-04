import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// 心情选择器
class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String>? onMoodChange;
  final bool enabled;

  const MoodSelector({
    super.key,
    this.selectedMood,
    this.onMoodChange,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '今天的心情怎么样？',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MoodOptions.values.map((mood) {
            final isSelected = selectedMood == mood.key;
            return _MoodButton(
              mood: mood,
              isSelected: isSelected,
              enabled: enabled,
              onTap: enabled ? () => onMoodChange?.call(mood.key) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 心情按钮
class _MoodButton extends StatelessWidget {
  final MoodOption mood;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _MoodButton({
    required this.mood,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? mood.color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? mood.color : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              mood.emoji,
              style: TextStyle(
                fontSize: 32,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? mood.color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 心情显示组件
class MoodDisplay extends StatelessWidget {
  final String? mood;
  final bool showLabel;

  const MoodDisplay({
    super.key,
    this.mood,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final moodOption = MoodOptions.options[mood];
    if (moodOption == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          moodOption.emoji,
          style: const TextStyle(fontSize: 20),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            moodOption.label,
            style: TextStyle(
              color: moodOption.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
