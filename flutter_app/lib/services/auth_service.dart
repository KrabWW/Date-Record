import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import 'api_client.dart';

part 'auth_service.g.dart';

/// 认证服务 Provider
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

/// 认证服务
class AuthService {
  final ApiClient _api = ApiClient();

  /// 用户注册
  Future<({String token, User user})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      final token = response.data['token'] as String;
      final user = User.fromJson(response.data['user']);

      // 保存 token
      await _api.saveToken(token);

      return (token: token, user: user);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// 用户登录
  Future<({String token, User user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'] as String;
      final user = User.fromJson(response.data['user']);

      // 保存 token
      await _api.saveToken(token);

      return (token: token, user: user);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// 获取当前用户信息
  Future<User> getMe() async {
    try {
      final response = await _api.get('/auth/me');
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// 更新用户资料
  Future<User> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _api.put('/auth/profile', data: data);
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // 忽略登出错误
    } finally {
      await _api.clearToken();
    }
  }

  /// 处理认证错误
  Exception _handleAuthError(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data != null && data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) {
        return ApiException(message.toString(), response?.statusCode);
      }
    }

    return ApiException(
      '认证失败，请稍后重试',
      response?.statusCode,
    );
  }
}
