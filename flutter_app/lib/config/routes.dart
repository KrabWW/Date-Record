import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/couple_setup/couple_setup_page.dart';
import '../pages/couple_setup/create_couple_page.dart';
import '../pages/couple_setup/join_couple_page.dart';
import '../pages/gallery/gallery_page.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/settings_page.dart';
import '../pages/records/record_detail_page.dart';
import '../pages/records/record_edit_page.dart';
import '../pages/records/records_page.dart';
import '../pages/wishlist/wishlist_page.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';

part 'routes.g.dart';

/// 用于触发 GoRouter refresh 的 ChangeNotifier
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// 路由配置 Provider
@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // 监听 auth 和 couple 状态变化，触发 GoRouter refresh
  ref.listen(currentUserProvider, (_, __) {
    refreshNotifier.refresh();
  });
  ref.listen(currentCoupleProvider, (_, __) {
    refreshNotifier.refresh();
  });

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(currentUserProvider);
      final coupleState = ref.read(currentCoupleProvider);

      final isAuthenticated = authState.value != null;

      // 未登录跳转到登录页
      if (!isAuthenticated &&
          state.matchedLocation != '/auth' &&
          state.matchedLocation != '/register') {
        return '/auth';
      }

      // couple 状态加载中，不做跳转（避免闪跳）
      if (coupleState.isLoading) return null;

      // 有情侣空间 = 已创建（不要求双方都加入）
      final hasCouple = coupleState.value != null;

      // 已登录且在登录/注册页，跳转到首页或情侣设置页
      if (isAuthenticated &&
          (state.matchedLocation == '/auth' ||
           state.matchedLocation == '/register')) {
        return hasCouple ? '/' : '/couple-setup';
      }

      // 已登录但无情侣空间，跳转到情侣设置页（含子路由放行）
      if (isAuthenticated &&
          !hasCouple &&
          !state.matchedLocation.startsWith('/couple-setup')) {
        return '/couple-setup';
      }

      return null;
    },
    routes: [
      // 认证相关路由
      GoRoute(
        path: '/auth',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // 情侣空间设置
      GoRoute(
        path: '/couple-setup',
        name: 'couple-setup',
        builder: (context, state) => const CoupleSetupPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-couple',
            builder: (context, state) => const CreateCouplePage(),
          ),
          GoRoute(
            path: 'join',
            name: 'join-couple',
            builder: (context, state) => const JoinCouplePage(),
          ),
        ],
      ),

      // 主应用路由（需要认证 + 情侣空间）
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/records',
        name: 'records',
        builder: (context, state) => const RecordsPage(),
      ),
      GoRoute(
        path: '/records/:id',
        name: 'record-detail',
        builder: (context, state) {
          // ignore: unused_local_variable
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return const RecordDetailPage();
        },
      ),
      GoRoute(
        path: '/records/new',
        name: 'record-new',
        builder: (context, state) => const RecordEditPage(),
      ),
      GoRoute(
        path: '/records/:id/edit',
        name: 'record-edit',
        builder: (context, state) {
          // ignore: unused_local_variable
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return const RecordEditPage();
        },
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryPage(),
      ),
      GoRoute(
        path: '/wishlists',
        name: 'wishlists',
        builder: (context, state) => const WishlistPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('页面未找到: ${state.uri}'),
          ],
        ),
      ),
    ),
  );
}
