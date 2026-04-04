import 'package:json_annotation/json_annotation.dart';

part 'couple.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Couple {
  final int id;
  final int user1Id;
  final int? user2Id;
  final String coupleName;
  final String inviteCode;
  final DateTime? anniversaryDate;
  final bool isActive;
  final DateTime createdAt;

  // 冗余字段，用于显示
  final String? user1Name;
  final String? user1Email;
  final String? user2Name;
  final String? user2Email;

  Couple({
    required this.id,
    required this.user1Id,
    this.user2Id,
    required this.coupleName,
    required this.inviteCode,
    this.anniversaryDate,
    required this.isActive,
    required this.createdAt,
    this.user1Name,
    this.user1Email,
    this.user2Name,
    this.user2Email,
  });

  factory Couple.fromJson(Map<String, dynamic> json) {
    // 后端 is_active 返回 0/1 (int)，需要转为 bool
    if (json.containsKey('is_active') && json['is_active'] is! bool) {
      json['is_active'] = (json['is_active'] as num) != 0;
    }
    if (json.containsKey('isActive') && json['isActive'] is! bool) {
      json['isActive'] = (json['isActive'] as num) != 0;
    }
    return _$CoupleFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CoupleToJson(this);

  Couple copyWith({
    int? id,
    int? user1Id,
    int? user2Id,
    String? coupleName,
    String? inviteCode,
    DateTime? anniversaryDate,
    bool? isActive,
    DateTime? createdAt,
    String? user1Name,
    String? user1Email,
    String? user2Name,
    String? user2Email,
  }) {
    return Couple(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      coupleName: coupleName ?? this.coupleName,
      inviteCode: inviteCode ?? this.inviteCode,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      user1Name: user1Name ?? this.user1Name,
      user1Email: user1Email ?? this.user1Email,
      user2Name: user2Name ?? this.user2Name,
      user2Email: user2Email ?? this.user2Email,
    );
  }

  bool get isComplete => user2Id != null;

  int? getPartnerId(int currentUserId) {
    if (user1Id == currentUserId) return user2Id;
    if (user2Id == currentUserId) return user1Id;
    return null;
  }
}
