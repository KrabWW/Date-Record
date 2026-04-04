import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/record.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';
import 'couple_provider.dart';

part 'wishlist_provider.g.dart';

/// 愿望清单列表 Provider
@riverpod
class WishlistList extends _$WishlistList {
  final WishlistService _service = WishlistService();

  @override
  Future<List<Wishlist>> build({String? status}) async {
    final couple = ref.watch(currentCoupleProvider);
    if (couple.value == null) return [];

    try {
      return await _service.getAll(status: status);
    } catch (e) {
      return [];
    }
  }

  /// 切换状态过滤
  void filterByStatus(String? newStatus) {
    ref.invalidateSelf();
    state = AsyncValue.data([]);
  }

  /// 创建愿望
  Future<void> createWishlist({
    required String title,
    String? description,
    int priority = 1,
    DateTime? targetDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newWishlist = await _service.create(
        title: title,
        description: description,
        priority: priority,
        targetDate: targetDate,
      );

      final previousData = state.valueOrNull ?? [];
      return [...previousData, newWishlist];
    });
  }

  /// 更新愿望
  Future<void> updateWishlist(
    int id, {
    String? title,
    String? description,
    int? priority,
    DateTime? targetDate,
  }) async {
    state = await AsyncValue.guard(() async {
      final updated = await _service.update(
        id,
        title: title,
        description: description,
        priority: priority,
        targetDate: targetDate,
      );

      final previousData = state.valueOrNull ?? [];
      return previousData.map((w) => w.id == id ? updated : w).toList();
    });
  }

  /// 删除愿望
  Future<void> deleteWishlist(int id) async {
    state = await AsyncValue.guard(() async {
      await _service.delete(id);

      final previousData = state.valueOrNull ?? [];
      return previousData.where((w) => w.id != id).toList();
    });
  }

  /// 切换完成状态
  Future<void> toggleComplete(int id, bool isCompleted) async {
    state = await AsyncValue.guard(() async {
      final updated = await _service.toggleComplete(id, isCompleted);

      final previousData = state.valueOrNull ?? [];
      return previousData.map((w) => w.id == id ? updated : w).toList();
    });
  }

  /// 转换为约会记录
  Future<DatingRecord> convertToDatingRecord(
    int id, {
    required String title,
    String? description,
    required DateTime recordDate,
    String? location,
    String mood = 'good',
    List<String>? emotionTags,
  }) async {
    return await _service.convertToRecord(
      id,
      title: title,
      description: description,
      recordDate: recordDate,
      location: location,
      mood: mood,
      emotionTags: emotionTags,
    );
  }

  /// 刷新
  Future<void> refresh() async {
    final couple = ref.watch(currentCoupleProvider);
    if (couple.value == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = await AsyncValue.guard(() async {
      return await _service.getAll();
    });
  }
}
