// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatar_url'] as String?,
  isVip: json['is_vip'] as bool,
  usedStorage: (json['used_storage'] as num).toInt(),
  vipExpiresAt: json['vip_expires_at'] == null
      ? null
      : DateTime.parse(json['vip_expires_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
  'is_vip': instance.isVip,
  'used_storage': instance.usedStorage,
  'vip_expires_at': instance.vipExpiresAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
