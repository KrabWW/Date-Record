import 'package:dio/dio.dart';
import '../models/wishlist.dart';
import '../models/record.dart';
import 'api_client.dart';

/// 愿望清单服务
class WishlistService {
  final ApiClient _api = ApiClient();

  /// 获取愿望列表
  Future<List<Wishlist>> getAll({String? status}) async {
    try {
      final response = await _api.get('/wishlists', queryParameters: {
        if (status != null) 'status': status,
      });

      final wishlists = response.data['wishlists'];
      if (wishlists == null) return [];
      return (wishlists as List).map((e) => Wishlist.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建愿望
  Future<Wishlist> create({
    required String title,
    String? description,
    int priority = 1,
    DateTime? targetDate,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'priority': priority,
      };
      if (description != null) data['description'] = description;
      if (targetDate != null) {
        data['target_date'] = targetDate.toIso8601String().split('T')[0];
      }

      final response = await _api.post('/wishlists', data: data);
      return Wishlist.fromJson(response.data['wishlist']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新愿望
  Future<Wishlist> update(
    int id, {
    String? title,
    String? description,
    int? priority,
    DateTime? targetDate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (priority != null) data['priority'] = priority;
      if (targetDate != null) {
        data['target_date'] = targetDate.toIso8601String().split('T')[0];
      }

      final response = await _api.put('/wishlists/$id', data: data);
      return Wishlist.fromJson(response.data['wishlist']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除愿望
  Future<String> delete(int id) async {
    try {
      final response = await _api.delete('/wishlists/$id');
      return response.data['message'] ?? '删除成功';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 切换完成状态
  Future<Wishlist> toggleComplete(int id, bool isCompleted) async {
    try {
      final response = await _api.patch('/wishlists/$id/complete', data: {
        'is_completed': isCompleted,
      });
      return Wishlist.fromJson(response.data['wishlist']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 转换为约会记录
  Future<DatingRecord> convertToRecord(
    int id, {
    required String title,
    String? description,
    required DateTime recordDate,
    String? location,
    String mood = 'good',
    List<String>? emotionTags,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'record_date': recordDate.toIso8601String().split('T')[0],
        'mood': mood,
      };
      if (description != null) data['description'] = description;
      if (location != null) data['location'] = location;
      if (emotionTags != null && emotionTags.isNotEmpty) {
        data['emotion_tags'] = emotionTags.join(' ');
      }

      final response = await _api.post('/wishlists/$id/convert-to-record',
          data: data);
      return DatingRecord.fromJson(response.data['record']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data != null && data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) {
        return ApiException(message.toString(), response?.statusCode);
      }
    }

    return ApiException(
      '操作失败，请稍后重试',
      response?.statusCode,
    );
  }
}
