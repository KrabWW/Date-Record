import 'package:dio/dio.dart';
import '../models/record.dart';
import 'api_client.dart';

/// 约会记录服务
class RecordService {
  final ApiClient _api = ApiClient();

  /// 获取记录列表
  Future<({List<DatingRecord> records, Map<String, dynamic> pagination})> getAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? mood,
  }) async {
    try {
      final response = await _api.get('/records', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (mood != null) 'mood': mood,
      });

      final records =
          (response.data['records'] as List).map((e) => DatingRecord.fromJson(e)).toList();
      final pagination = response.data['pagination'] as Map<String, dynamic>;

      return (records: records, pagination: pagination);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取单个记录详情
  Future<DatingRecord> getById(int id) async {
    try {
      final response = await _api.get('/records/$id');
      return DatingRecord.fromJson(response.data['record']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建记录
  Future<DatingRecord> create({
    required String title,
    String? description,
    required DateTime recordDate,
    String? location,
    String mood = 'good',
    List<String>? emotionTags,
    List<String>? tags,
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
      if (tags != null && tags.isNotEmpty) {
        data['tags'] = tags.join(' ');
      }

      final response = await _api.post('/records', data: data);
      return DatingRecord.fromJson(response.data['record']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新记录
  Future<DatingRecord> update(
    int id, {
    String? title,
    String? description,
    DateTime? recordDate,
    String? location,
    String? mood,
    List<String>? emotionTags,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (recordDate != null) {
        data['record_date'] = recordDate.toIso8601String().split('T')[0];
      }
      if (location != null) data['location'] = location;
      if (mood != null) data['mood'] = mood;
      if (emotionTags != null) {
        data['emotion_tags'] = emotionTags.join(' ');
      }
      if (tags != null) data['tags'] = tags.join(' ');

      final response = await _api.put('/records/$id', data: data);
      return DatingRecord.fromJson(response.data['record']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除记录
  Future<String> delete(int id) async {
    try {
      final response = await _api.delete('/records/$id');
      return response.data['message'] ?? '删除成功';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _api.get('/records/stats/summary');
      return Map<String, dynamic>.from(response.data);
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
