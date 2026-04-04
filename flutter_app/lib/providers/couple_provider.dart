import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/couple.dart';
import '../models/user.dart';
import '../services/couple_service.dart';
import 'auth_provider.dart';

part 'couple_provider.g.dart';

/// 当前情侣空间 Provider
@riverpod
class CurrentCouple extends _$CurrentCouple {
  final CoupleService _service = CoupleService();

  @override
  Future<Couple?> build() async {
    // 尝试从本地存储加载
    final prefs = await SharedPreferences.getInstance();
    final coupleJson = prefs.getString(StorageKeys.couple);
    if (coupleJson != null) {
      try {
        // TODO: Parse and return couple from JSON
      } catch (e) {
        // Ignore parse errors
      }
    }

    // 检查用户是否已认证
    final user = ref.watch(currentUserProvider);
    if (user.value == null) return null;

    // 从服务器获取情侣空间信息
    try {
      return await _service.getCurrent();
    } catch (e) {
      return null;
    }
  }

  /// 创建情侣空间
  Future<void> createCouple({
    required String coupleName,
    DateTime? anniversaryDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.create(
        coupleName: coupleName,
        anniversaryDate: anniversaryDate,
      );
    });
  }

  /// 加入情侣空间
  Future<void> joinCouple(String inviteCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.join(inviteCode);
    });
  }

  /// 更新情侣空间
  Future<void> updateCouple({
    String? coupleName,
    DateTime? anniversaryDate,
  }) async {
    final current = state.value;
    if (current == null) return;

    state = await AsyncValue.guard(() async {
      return await _service.update(
        coupleName: coupleName,
        anniversaryDate: anniversaryDate,
      );
    });
  }

  /// 删除情侣空间
  Future<void> deleteCouple() async {
    state = const AsyncValue.loading();
    try {
      await _service.delete();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 刷新
  Future<void> refresh() async {
    final user = ref.watch(currentUserProvider);
    if (user.value == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = await AsyncValue.guard(() async {
      return await _service.getCurrent();
    });
  }
}

/// 是否有情侣空间 Provider
@riverpod
bool hasCouple(HasCoupleRef ref) {
  final couple = ref.watch(currentCoupleProvider);
  return couple.value?.isComplete ?? false;
}

/// 获取伴侣信息 Provider
@riverpod
({
  String? name,
  String? email,
}) partner(PartnerRef ref) {
  final couple = ref.watch(currentCoupleProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (couple.value == null || currentUserId == null) {
    return (name: null, email: null);
  }

  final c = couple.value!;
  if (c.user1Id == currentUserId) {
    return (name: c.user2Name, email: c.user2Email);
  } else {
    return (name: c.user1Name, email: c.user1Email);
  }
}

/// 获取伴侣 ID Provider
@riverpod
int? partnerId(PartnerIdRef ref) {
  final couple = ref.watch(currentCoupleProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (couple.value == null || currentUserId == null) return null;

  return couple.value!.getPartnerId(currentUserId);
}
