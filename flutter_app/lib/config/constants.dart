import 'package:flutter/material.dart';

/// 心情选项配置
class MoodOptions {
  static const Map<String, MoodOption> options = {
    'amazing': MoodOption(
      key: 'amazing',
      emoji: '🥰',
      label: '超开心',
      color: Color(0xFFFF6B9D),
      description: '今天太棒了！',
    ),
    'happy': MoodOption(
      key: 'happy',
      emoji: '😊',
      label: '很开心',
      color: Color(0xFFFF8FB3),
      description: '心情很好',
    ),
    'good': MoodOption(
      key: 'good',
      emoji: '😌',
      label: '挺不错',
      color: Color(0xFFFFB3C6),
      description: '感觉还可以',
    ),
    'okay': MoodOption(
      key: 'okay',
      emoji: '😐',
      label: '一般般',
      color: Color(0xFFC4C4C4),
      description: '平平淡淡',
    ),
    'meh': MoodOption(
      key: 'meh',
      emoji: '😕',
      label: '不太好',
      color: Color(0xFF9E9E9E),
      description: '有点不开心',
    ),
  };

  static List<String> get keys => options.keys.toList();
  static List<MoodOption> get values => options.values.toList();
}

class MoodOption {
  final String key;
  final String emoji;
  final String label;
  final Color color;
  final String description;

  const MoodOption({
    required this.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.description,
  });
}

/// 情绪标签配置
class EmotionTags {
  static const List<EmotionTag> tags = [
    EmotionTag(
      id: 'romantic',
      label: '浪漫',
      emoji: '💕',
      color: Color(0xFFFF69B4),
    ),
    EmotionTag(
      id: 'fun',
      label: '有趣',
      emoji: '😄',
      color: Color(0xFFFFA500),
    ),
    EmotionTag(
      id: 'peaceful',
      label: '安静',
      emoji: '😌',
      color: Color(0xFF87CEEB),
    ),
    EmotionTag(
      id: 'exciting',
      label: '刺激',
      emoji: '🤩',
      color: Color(0xFFFF4500),
    ),
    EmotionTag(
      id: 'cozy',
      label: '温馨',
      emoji: '🤗',
      color: Color(0xFFDDA0DD),
    ),
    EmotionTag(
      id: 'adventurous',
      label: '冒险',
      emoji: '🌟',
      color: Color(0xFF32CD32),
    ),
    EmotionTag(
      id: 'relaxing',
      label: '放松',
      emoji: '😊',
      color: Color(0xFF98FB98),
    ),
    EmotionTag(
      id: 'sweet',
      label: '甜蜜',
      emoji: '🍯',
      color: Color(0xFFFFB6C1),
    ),
    EmotionTag(
      id: 'surprise',
      label: '惊喜',
      emoji: '🎉',
      color: Color(0xFFFF6347),
    ),
    EmotionTag(
      id: 'intimate',
      label: '亲密',
      emoji: '💑',
      color: Color(0xFFDA70D6),
    ),
    EmotionTag(
      id: 'sweetness_overload',
      label: '甜度爆表',
      emoji: '🍭',
      color: Color(0xFFFF1493),
    ),
    EmotionTag(
      id: 'heart_flutter',
      label: '小鹿乱撞',
      emoji: '🦌',
      color: Color(0xFFFF69B4),
    ),
    EmotionTag(
      id: 'roller_coaster',
      label: '过山车',
      emoji: '🎢',
      color: Color(0xFFFF4500),
    ),
    EmotionTag(
      id: 'after_rain',
      label: '雨过天晴',
      emoji: '🌈',
      color: Color(0xFF87CEEB),
    ),
    EmotionTag(
      id: 'healing',
      label: '治愈',
      emoji: '🌱',
      color: Color(0xFF90EE90),
    ),
    EmotionTag(
      id: 'looking_forward',
      label: '期待再见',
      emoji: '🤗',
      color: Color(0xFFDDA0DD),
    ),
    EmotionTag(
      id: 'disappointing',
      label: '下头',
      emoji: '😮‍💨',
      color: Color(0xFF708090),
    ),
  ];

  static EmotionTag? getById(String id) {
    try {
      return tags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }
}

class EmotionTag {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const EmotionTag({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

/// 优先级配置
class PriorityOptions {
  static const Map<int, PriorityOption> options = {
    1: PriorityOption(
      value: 1,
      label: '低',
      color: Color(0xFF4CAF50),
    ),
    2: PriorityOption(
      value: 2,
      label: '较低',
      color: Color(0xFF8BC34A),
    ),
    3: PriorityOption(
      value: 3,
      label: '中等',
      color: Color(0xFFFFA726),
    ),
    4: PriorityOption(
      value: 4,
      label: '较高',
      color: Color(0xFFFF7043),
    ),
    5: PriorityOption(
      value: 5,
      label: '高',
      color: Color(0xFFF44336),
    ),
  };

  static PriorityOption? getByValue(int value) => options[value];
}

class PriorityOption {
  final int value;
  final String label;
  final Color color;

  const PriorityOption({
    required this.value,
    required this.label,
    required this.color,
  });
}

/// 存储限制配置
class StorageLimits {
  static const int freeStorageMB = 100; // 免费用户 100MB
  static const int vipStorageMB = 1024; // VIP 用户 1GB

  static int getMaxStorage(bool isVip) {
    return isVip ? vipStorageMB : freeStorageMB;
  }

  static String formatStorage(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// API 常量
class ApiConstants {
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int sendTimeout = 15000;
}

/// 分页常量
class PaginationConstants {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// 本地存储键
class StorageKeys {
  static const String token = 'auth_token';
  static const String user = 'user_data';
  static const String couple = 'couple_data';
}
