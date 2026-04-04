import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import 'couple_provider.dart';

part 'record_provider.g.dart';

/// 记录列表 Provider
@riverpod
class RecordList extends _$RecordList {
  final RecordService _service = RecordService();

  @override
  Future<List<DatingRecord>> build() async {
    final couple = ref.watch(currentCoupleProvider);
    if (couple.value == null) return [];

    try {
      final result = await _service.getAll();
      return result.records;
    } catch (e) {
      return [];
    }
  }

  /// 加载更多记录
  Future<void> loadMore({int page = 1}) async {
    final couple = ref.watch(currentCoupleProvider);
    if (couple.value == null) return;

    final previousData = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final result = await _service.getAll(page: page);
      return [...previousData, ...result.records];
    });
  }

  /// 搜索记录
  Future<void> search({String? query, String? mood}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _service.getAll(search: query, mood: mood);
      return result.records;
    });
  }

  /// 刷新
  Future<void> refresh() async {
    final couple = ref.watch(currentCoupleProvider);
    if (couple.value == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = await AsyncValue.guard(() async {
      final result = await _service.getAll();
      return result.records;
    });
  }
}

/// 当前记录 Provider (用于编辑)
@riverpod
class CurrentRecord extends _$CurrentRecord {
  final RecordService _service = RecordService();

  @override
  Future<DatingRecord?> build(int? recordId) async {
    if (recordId == null) return null;
    try {
      return await _service.getById(recordId);
    } catch (e) {
      return null;
    }
  }

  /// 创建记录
  Future<void> createRecord({
    required String title,
    String? description,
    required DateTime recordDate,
    String? location,
    String mood = 'good',
    List<String>? emotionTags,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.create(
        title: title,
        description: description,
        recordDate: recordDate,
        location: location,
        mood: mood,
        emotionTags: emotionTags,
        tags: tags,
      );
    });

    // 刷新列表
    ref.invalidate(recordListProvider);
  }

  /// 更新记录
  Future<void> updateRecord({
    String? title,
    String? description,
    DateTime? recordDate,
    String? location,
    String? mood,
    List<String>? emotionTags,
    List<String>? tags,
  }) async {
    final current = state.value;
    if (current == null) return;

    state = await AsyncValue.guard(() async {
      return await _service.update(
        current.id,
        title: title,
        description: description,
        recordDate: recordDate,
        location: location,
        mood: mood,
        emotionTags: emotionTags,
        tags: tags,
      );
    });

    // 刷新列表
    ref.invalidate(recordListProvider);
  }

  /// 删除记录
  Future<void> deleteRecord() async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncValue.loading();

    try {
      await _service.delete(current.id);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }

    // 刷新列表
    ref.invalidate(recordListProvider);
  }

  /// 重置
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// 记录统计 Provider
@riverpod
Future<Map<String, dynamic>> recordStats(RecordStatsRef ref) async {
  final couple = ref.watch(currentCoupleProvider);
  if (couple.value == null) return {};

  try {
    final service = RecordService();
    return await service.getStats();
  } catch (e) {
    return {};
  }
}
