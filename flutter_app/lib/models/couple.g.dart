// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Couple _$CoupleFromJson(Map<String, dynamic> json) => Couple(
  id: (json['id'] as num).toInt(),
  user1Id: (json['user1_id'] as num).toInt(),
  user2Id: (json['user2_id'] as num?)?.toInt(),
  coupleName: json['couple_name'] as String,
  inviteCode: json['invite_code'] as String,
  anniversaryDate: json['anniversary_date'] == null
      ? null
      : DateTime.parse(json['anniversary_date'] as String),
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  user1Name: json['user1_name'] as String?,
  user1Email: json['user1_email'] as String?,
  user2Name: json['user2_name'] as String?,
  user2Email: json['user2_email'] as String?,
);

Map<String, dynamic> _$CoupleToJson(Couple instance) => <String, dynamic>{
  'id': instance.id,
  'user1_id': instance.user1Id,
  'user2_id': instance.user2Id,
  'couple_name': instance.coupleName,
  'invite_code': instance.inviteCode,
  'anniversary_date': instance.anniversaryDate?.toIso8601String(),
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'user1_name': instance.user1Name,
  'user1_email': instance.user1Email,
  'user2_name': instance.user2Name,
  'user2_email': instance.user2Email,
};
