import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Media {
  final int id;
  final int coupleId;
  final int? recordId;
  final String fileUrl;
  final String fileType;
  final String? caption;
  final int? fileSize;
  final String? mimeType;
  final int? duration;
  final String? thumbnailUrl;
  final DateTime createdAt;

  Media({
    required this.id,
    required this.coupleId,
    this.recordId,
    required this.fileUrl,
    required this.fileType,
    this.caption,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  Map<String, dynamic> toJson() => _$MediaToJson(this);

  Media copyWith({
    int? id,
    int? coupleId,
    int? recordId,
    String? fileUrl,
    String? fileType,
    String? caption,
    int? fileSize,
    String? mimeType,
    int? duration,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return Media(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      recordId: recordId ?? this.recordId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      caption: caption ?? this.caption,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPhoto => fileType == 'photo';
  bool get isVideo => fileType == 'video';

  String get displayUrl => thumbnailUrl ?? fileUrl;
}
