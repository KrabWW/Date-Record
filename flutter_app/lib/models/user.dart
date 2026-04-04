import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool isVip;
  final int usedStorage;
  final DateTime? vipExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.isVip,
    required this.usedStorage,
    this.vipExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 后端 is_vip 返回 0/1 (int)，需要转为 bool
    if (json.containsKey('is_vip') && json['is_vip'] is! bool) {
      json['is_vip'] = (json['is_vip'] as num) != 0;
    }
    if (json.containsKey('isVip') && json['isVip'] is! bool) {
      json['isVip'] = (json['isVip'] as num) != 0;
    }
    return _$UserFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? isVip,
    int? usedStorage,
    DateTime? vipExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVip: isVip ?? this.isVip,
      usedStorage: usedStorage ?? this.usedStorage,
      vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
