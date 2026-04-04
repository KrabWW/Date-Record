// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Media _$MediaFromJson(Map<String, dynamic> json) => Media(
  id: (json['id'] as num).toInt(),
  coupleId: (json['couple_id'] as num).toInt(),
  recordId: (json['record_id'] as num?)?.toInt(),
  fileUrl: json['file_url'] as String,
  fileType: json['file_type'] as String,
  caption: json['caption'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  mimeType: json['mime_type'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  thumbnailUrl: json['thumbnail_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
  'id': instance.id,
  'couple_id': instance.coupleId,
  'record_id': instance.recordId,
  'file_url': instance.fileUrl,
  'file_type': instance.fileType,
  'caption': instance.caption,
  'file_size': instance.fileSize,
  'mime_type': instance.mimeType,
  'duration': instance.duration,
  'thumbnail_url': instance.thumbnailUrl,
  'created_at': instance.createdAt.toIso8601String(),
};
