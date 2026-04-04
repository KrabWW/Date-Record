import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:love4lili_flutter/main.dart' as app;
import 'helpers/test_helpers.dart';

/// 注册 + 登录辅助函数（用于 couple_setup_test 内联场景）
Future<String> _registerAndLogin(PatrolIntegrationTester $) async {
  final email = 'patrol_${DateTime.now().millisecondsSinceEpoch}@test.com';

  // 注册
  await $('立即注册').tap();
  await $.pumpAndTrySettle();

  await enterTextAndDismissKeyboard($, const Key('register_name'), 'Patrol Tester');
  await enterTextAndDismissKeyboard($, const Key('register_email'), email);
  await enterTextAndDismissKeyboard($, const Key('register_password'), 'Test123456');
  await enterTextAndDismissKeyboard($, const Key('register_confirm_password'), 'Test123456');

  await $('创建账号').tap();
  await $.pumpAndTrySettle();

  // 等待跳转回登录页
  await $('登录').waitUntilVisible(timeout: const Duration(seconds: 30));

  // 登录
  await enterTextAndDismissKeyboard($, const Key('login_email'), email);
  await enterTextAndDismissKeyboard($, const Key('login_password'), 'Test123456');
  await $('登录').tap();
  await $.pumpAndTrySettle();

  // 等待登录 API 完成并导航
  for (int i = 0; i < 5; i++) {
    await $.pump(const Duration(seconds: 1));
  }
  await $.pumpAndTrySettle();

  // 诊断：登录后在哪个页面？
  print('===== 登录后诊断 =====');
  print('登录按钮: ${$('登录').exists}');
  print('创建新的情侣空间: ${$('创建新的情侣空间').exists}');
  print('加入伴侣的空间: ${$('加入伴侣的空间').exists}');
  print('首页记录: ${$('记录').exists}');
  print('创建空间: ${$('创建空间').exists}');
  print('错误: ${$('错误').exists}, 失败: ${$('失败').exists}, 密码: ${$('密码').exists}');
  print('===== 诊断结束 =====');

  return email;
}

void main() {
  // 场景 1：注册后登录，创建情侣空间成功，验证创建成功页
  patrolTest(
    '注册登录后创建情侣空间 - 验证创建成功页显示邀请码',
    config: PatrolTesterConfig(visibleTimeout: const Duration(seconds: 20), settleTimeout: const Duration(seconds: 20), printLogs: true),
    ($) async {
      await clearAppStorage();
      app.main();
      await $.pumpAndTrySettle();

      // 注册 + 登录
      await _registerAndLogin($);

      // --- couple-setup 页 ---
      await $.pumpAndTrySettle();

      // 等待 couple-setup 页加载
      for (int i = 0; i < 5; i++) {
        await $.pump(const Duration(seconds: 1));
      }
      await $.pumpAndTrySettle();

      // 诊断
      print('===== couple-setup 诊断 =====');
      print('创建新的情侣空间: ${$('创建新的情侣空间').exists}');
      print('加入伴侣的空间: ${$('加入伴侣的空间').exists}');
      print('登录按钮: ${$('登录').exists}');
      print('===== 诊断结束 =====');

      await $('创建新的情侣空间').waitUntilVisible(timeout: const Duration(seconds: 30));
      await $.pumpAndTrySettle();

      // 点击「创建新的情侣空间」进入创建页
      await $('创建新的情侣空间').tap();
      await $.pumpAndTrySettle();

      // --- create-couple 页 ---
      await enterTextAndDismissKeyboard($, const Key('create_couple_name'), 'Patrol Couple');
      await $('创建空间').tap();
      await $.pumpAndTrySettle();

      // --- 验证创建成功页（等待 API 完成） ---
      await $('创建成功！').waitUntilVisible(timeout: const Duration(seconds: 30));
      expect($('邀请码'), findsWidgets);
    },
  );

  // 场景 2：创建成功后点击「进入首页」，验证跳转
  patrolTest(
    '创建情侣空间成功后点击进入首页 - 验证跳转到首页',
    config: PatrolTesterConfig(visibleTimeout: const Duration(seconds: 20), settleTimeout: const Duration(seconds: 20), printLogs: true),
    ($) async {
      await clearAppStorage();
      app.main();
      await $.pumpAndTrySettle();

      await _registerAndLogin($);

      // --- couple-setup 页 → create-couple 页 ---
      await $.pumpAndTrySettle();
      await $('创建新的情侣空间').tap();
      await $.pumpAndTrySettle();

      await enterTextAndDismissKeyboard($, const Key('create_couple_name'), 'Patrol Couple');
      await $('创建空间').tap();
      await $.pumpAndTrySettle();

      // 确认创建成功后点击「进入首页」
      await $('创建成功！').waitUntilVisible(timeout: const Duration(seconds: 30));
      await $('进入首页').tap();
      await $.pumpAndTrySettle();

      // --- 验证跳转到首页 ---
      expect($('创建空间'), findsNothing);
      expect($('创建新的情侣空间'), findsNothing);
    },
  );

  // 场景 3：填写无效邀请码，验证错误提示
  patrolTest(
    '填写无效邀请码加入情侣空间 - 验证错误提示',
    config: PatrolTesterConfig(visibleTimeout: const Duration(seconds: 20), settleTimeout: const Duration(seconds: 20), printLogs: true),
    ($) async {
      await clearAppStorage();
      app.main();
      await $.pumpAndTrySettle();

      await _registerAndLogin($);

      // --- couple-setup 页 ---
      await $.pumpAndTrySettle();
      await $('加入伴侣的空间').tap();
      await $.pumpAndTrySettle();

      // --- join-couple 页：填写无效的 8 位邀请码 ---
      await $(TextField).at(0).enterText('INVALID1');
      await $('加入空间').tap();
      await $.pumpAndTrySettle();

      // 验证页面仍停留在加入页
      expect($('加入空间'), findsOneWidget);
    },
  );
}
