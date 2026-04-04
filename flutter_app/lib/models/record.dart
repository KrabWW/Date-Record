import 'package:json_annotation/json_annotation.dart';
import 'media.dart';

part 'record.g.dart';

/// 约会记录模型（重命名为 DatingRecord 以避免与 dart:core.Record 冲突）
@JsonSerializable(fieldRename: FieldRename.snake)
class DatingRecord {
  final int id;
  final int coupleId;
  final int createdBy;
  final String title;
  final String? description;
  final DateTime recordDate;
  final String? location;
  final String mood;
  @JsonKey(fromJson: _emotionTagsFromJson, toJson: _emotionTagsToJson)
  final List<String> emotionTags;
  @JsonKey(fromJson: _tagsFromJson, toJson: _tagsToJson)
  final List<String> tags;
  @JsonKey(fromJson: _photosFromJson, toJson: _photosToJson)
  final List<Media> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  DatingRecord({
    required this.id,
    required this.coupleId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.recordDate,
    this.location,
    required this.mood,
    required this.emotionTags,
    required this.tags,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DatingRecord.fromJson(Map<String, dynamic> json) => _$DatingRecordFromJson(json);

  Map<String, dynamic> toJson() => _$DatingRecordToJson(this);

  DatingRecord copyWith({
    int? id,
    int? coupleId,
    int? createdBy,
    String? title,
    String? description,
    DateTime? recordDate,
    String? location,
    String? mood,
    List<String>? emotionTags,
    List<String>? tags,
    List<Media>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatingRecord(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      recordDate: recordDate ?? this.recordDate,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      emotionTags: emotionTags ?? this.emotionTags,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON 转换辅助方法
  static List<String> _emotionTagsFromJson(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        final List<dynamic> decoded = value.replaceAll("'", '"').split(' ');
        return decoded.cast<String>();
      } catch (e) {
        return [];
      }
    }
    if (value is List) return value.cast<String>();
    return [];
  }

  static String? _emotionTagsToJson(List<String> value) {
    if (value.isEmpty) return null;
    return value.join(' ');
  }

  static List<String> _tagsFromJson(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        return List<String>.from(value.replaceAll("'", '"').split(' '));
      } catch (e) {
        return [];
      }
    }
    if (value is List) return value.cast<String>();
    return [];
  }

  static String? _tagsToJson(List<String> value) {
    if (value.isEmpty) return null;
    return value.join(' ');
  }

  static List<Media> _photosFromJson(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => Media.fromJson(e)).toList();
    }
    return [];
  }

  static List<Map<String, dynamic>>? _photosToJson(List<Media> value) {
    if (value.isEmpty) return null;
    return value.map((e) => e.toJson()).toList();
  }
}
