import 'package:json_annotation/json_annotation.dart';

part 'wishlist.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Wishlist {
  final int id;
  final int coupleId;
  final String title;
  final String? description;
  final int priority;
  final bool isCompleted;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final DateTime createdAt;

  Wishlist({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.priority,
    required this.isCompleted,
    this.targetDate,
    this.completedDate,
    required this.createdAt,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    // 后端 is_completed 返回 0/1 (int)，需要转为 bool
    if (json.containsKey('is_completed') && json['is_completed'] is! bool) {
      json['is_completed'] = (json['is_completed'] as num) != 0;
    }
    if (json.containsKey('isCompleted') && json['isCompleted'] is! bool) {
      json['isCompleted'] = (json['isCompleted'] as num) != 0;
    }
    return _$WishlistFromJson(json);
  }

  Map<String, dynamic> toJson() => _$WishlistToJson(this);

  Wishlist copyWith({
    int? id,
    int? coupleId,
    String? title,
    String? description,
    int? priority,
    bool? isCompleted,
    DateTime? targetDate,
    DateTime? completedDate,
    DateTime? createdAt,
  }) {
    return Wishlist(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
