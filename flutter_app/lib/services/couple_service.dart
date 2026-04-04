import 'package:dio/dio.dart';
import '../models/couple.dart';
import 'api_client.dart';

/// 情侣空间服务
class CoupleService {
  final ApiClient _api = ApiClient();

  /// 创建情侣空间
  Future<Couple> create({
    required String coupleName,
    DateTime? anniversaryDate,
  }) async {
    try {
      final data = <String, dynamic>{
        'couple_name': coupleName,
      };
      if (anniversaryDate != null) {
        data['anniversary_date'] =
            anniversaryDate.toIso8601String().split('T')[0];
      }

      final response = await _api.post('/couples', data: data);
      return Couple.fromJson(response.data['couple']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 通过邀请码加入情侣空间
  Future<Couple> join(String inviteCode) async {
    try {
      final response = await _api.post('/couples/join', data: {
        'invite_code': inviteCode,
      });
      return Couple.fromJson(response.data['couple']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取当前情侣空间
  Future<Couple> getCurrent() async {
    try {
      final response = await _api.get('/couples/me');
      return Couple.fromJson(response.data['couple']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新情侣空间信息
  Future<Couple> update({
    String? coupleName,
    DateTime? anniversaryDate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (coupleName != null) data['couple_name'] = coupleName;
      if (anniversaryDate != null) {
        data['anniversary_date'] =
            anniversaryDate.toIso8601String().split('T')[0];
      }

      final response = await _api.put('/couples/me', data: data);
      return Couple.fromJson(response.data['couple']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 解除情侣关系
  Future<void> delete() async {
    try {
      await _api.delete('/couples/me');
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
