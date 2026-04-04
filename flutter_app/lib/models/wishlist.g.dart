// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wishlist _$WishlistFromJson(Map<String, dynamic> json) => Wishlist(
  id: (json['id'] as num).toInt(),
  coupleId: (json['couple_id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  priority: (json['priority'] as num).toInt(),
  isCompleted: json['is_completed'] as bool,
  targetDate: json['target_date'] == null
      ? null
      : DateTime.parse(json['target_date'] as String),
  completedDate: json['completed_date'] == null
      ? null
      : DateTime.parse(json['completed_date'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WishlistToJson(Wishlist instance) => <String, dynamic>{
  'id': instance.id,
  'couple_id': instance.coupleId,
  'title': instance.title,
  'description': instance.description,
  'priority': instance.priority,
  'is_completed': instance.isCompleted,
  'target_date': instance.targetDate?.toIso8601String(),
  'completed_date': instance.completedDate?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
