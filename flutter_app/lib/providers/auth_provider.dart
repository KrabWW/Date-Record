import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

part 'auth_provider.g.dart';

/// 当前用户 Provider
@riverpod
class CurrentUser extends _$CurrentUser {
  final ApiClient _api = ApiClient();

  @override
  Future<User?> build() async {
    // 尝试从本地存储加载用户
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(StorageKeys.user);
    if (userJson != null) {
      try {
        // TODO: Parse and return user from JSON
      } catch (e) {
        // Ignore parse errors
      }
    }

    // 从服务器获取用户信息
    final token = await _api.getToken();
    if (token == null) return null;

    try {
      final authService = AuthService();
      return await authService.getMe();
    } catch (e) {
      return null;
    }
  }

  /// 登录
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = AuthService();
      final result = await authService.login(email: email, password: password);
      return result.user;
    });
  }

  /// 注册
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = AuthService();
      final result = await authService.register(
        email: email,
        password: password,
        name: name,
      );
      return result.user;
    });
  }

  /// 更新用户资料
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = await AsyncValue.guard(() async {
      final authService = AuthService();
      return await authService.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
      );
    });
  }

  /// 登出
  Future<void> logout() async {
    // 先立即清除 auth state，防止 GoRouter redirect 在 API 调用期间误跳转
    state = const AsyncValue.data(null);

    final authService = AuthService();
    await authService.logout();

    // 清除本地用户数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.user);
  }

  /// 刷新用户信息
  Future<void> refresh() async {
    final token = await _api.getToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = await AsyncValue.guard(() async {
      final authService = AuthService();
      return await authService.getMe();
    });
  }
}

/// 是否已认证 Provider
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final userValue = ref.watch(currentUserProvider);
  return userValue.value != null;
}

/// 当前用户 ID Provider
@riverpod
int? currentUserId(CurrentUserIdRef ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.id;
}
