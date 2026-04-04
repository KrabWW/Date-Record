// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DatingRecord _$DatingRecordFromJson(Map<String, dynamic> json) => DatingRecord(
  id: (json['id'] as num).toInt(),
  coupleId: (json['couple_id'] as num).toInt(),
  createdBy: (json['created_by'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  recordDate: DateTime.parse(json['record_date'] as String),
  location: json['location'] as String?,
  mood: json['mood'] as String,
  emotionTags: DatingRecord._emotionTagsFromJson(json['emotion_tags']),
  tags: DatingRecord._tagsFromJson(json['tags']),
  photos: DatingRecord._photosFromJson(json['photos']),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DatingRecordToJson(DatingRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'couple_id': instance.coupleId,
      'created_by': instance.createdBy,
      'title': instance.title,
      'description': instance.description,
      'record_date': instance.recordDate.toIso8601String(),
      'location': instance.location,
      'mood': instance.mood,
      'emotion_tags': DatingRecord._emotionTagsToJson(instance.emotionTags),
      'tags': DatingRecord._tagsToJson(instance.tags),
      'photos': DatingRecord._photosToJson(instance.photos),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
