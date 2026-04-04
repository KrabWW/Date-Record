import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// 存储信息条
class StorageInfoBar extends StatelessWidget {
  final int usedStorage;
  final int? maxStorage;
  final bool isVip;

  const StorageInfoBar({
    super.key,
    required this.usedStorage,
    this.maxStorage,
    this.isVip = false,
  }) : assert(usedStorage >= 0, 'usedStorage must be non-negative');

  @override
  Widget build(BuildContext context) {
    final max = maxStorage ?? StorageLimits.getMaxStorage(isVip);
    final percentage = (usedStorage / max).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.9;
    final color = isNearLimit ? AppTheme.error : AppTheme.lovePink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isVip ? Icons.workspace_premium : Icons.folder_outlined,
                    size: 16,
                    color: isVip ? Colors.amber : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVip ? 'VIP 存储' : '免费存储',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isVip ? Colors.amber.shade700 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${StorageLimits.formatStorage(usedStorage)} / ${StorageLimits.formatStorage(max * 1024 * 1024)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isNearLimit ? AppTheme.error : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% 已使用',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 简化版存储信息显示
class StorageInfoText extends StatelessWidget {
  final int usedStorage;
  final int? maxStorage;
  final bool isVip;

  const StorageInfoText({
    super.key,
    required this.usedStorage,
    this.maxStorage,
    this.isVip = false,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxStorage ?? StorageLimits.getMaxStorage(isVip);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isVip ? Icons.workspace_premium : Icons.folder_outlined,
          size: 14,
          color: isVip ? Colors.amber : AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${StorageLimits.formatStorage(usedStorage)} / ${StorageLimits.formatStorage(max * 1024 * 1024)}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
