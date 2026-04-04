import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love4lili_flutter/main.dart' as app;

/// 每次测试使用唯一邮箱，避免冲突
String uniqueEmail() {
  return 'patrol_${DateTime.now().millisecondsSinceEpoch}@test.com';
}

/// 清除所有本地存储（JWT token、用户偏好等）
/// 必须在每次测试启动 app 之前调用，防止因上一次测试遗留的 token 导致自动登录
Future<void> clearAppStorage() async {
  // 清除 FlutterSecureStorage 中的 JWT token
  const storage = FlutterSecureStorage();
  await storage.deleteAll();

  // 清除 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

const String kTestPassword = 'Test123456';
const String kTestName = 'Patrol Tester';
const String kTestCoupleName = 'Patrol Couple';

/// Helper: 输入文本后取消焦点并等待布局稳定
Future<void> enterTextAndDismissKeyboard(
  PatrolIntegrationTester $,
  Key key,
  String text,
) async {
  await $(key).enterText(text);
  // 取消焦点 → 关闭软键盘
  FocusManager.instance.primaryFocus?.unfocus();
  // 等待键盘关闭和布局重新排列
  await Future.delayed(const Duration(milliseconds: 500));
  await $.pumpAndTrySettle();
}

/// 启动 App，完成注册 + 登录 + 创建情侣空间，进入首页
/// 返回注册使用的邮箱
Future<String> bootstrapApp(PatrolIntegrationTester $) async {
  await clearAppStorage();
  app.main();
  await $.pumpAndTrySettle();

  final email = uniqueEmail();
  await _register($, email: email);

  // 注册后回到登录页，用刚注册的账号登录
  await enterTextAndDismissKeyboard($, const Key('login_email'), email);
  await enterTextAndDismissKeyboard($, const Key('login_password'), kTestPassword);
  await $('登录').tap();
  await $.pumpAndTrySettle();

  await _createCouple($);

  return email;
}

/// 注册新用户（4 个字段：昵称、邮箱、密码、确认密码）
/// 注册成功后会自动跳转回登录页
Future<void> _register(
  PatrolIntegrationTester $, {
  required String email,
  String name = kTestName,
  String password = kTestPassword,
}) async {
  // 从登录页进入注册页
  await $('立即注册').tap();
  await $.pumpAndTrySettle();

  await enterTextAndDismissKeyboard($, const Key('register_name'), name);
  await enterTextAndDismissKeyboard($, const Key('register_email'), email);
  await enterTextAndDismissKeyboard($, const Key('register_password'), password);
  await enterTextAndDismissKeyboard($, const Key('register_confirm_password'), password);

  // 提交注册
  await $('创建账号').tap();
  await $.pumpAndTrySettle();

  // 注册成功后跳转回登录页，等待登录按钮出现
  await $('登录').waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
}

/// 登录已有账号
Future<void> loginApp(
  PatrolIntegrationTester $, {
  required String email,
  String password = kTestPassword,
}) async {
  await clearAppStorage();
  app.main();
  await $.pumpAndTrySettle();

  await enterTextAndDismissKeyboard($, const Key('login_email'), email);
  await enterTextAndDismissKeyboard($, const Key('login_password'), password);

  await $('登录').tap();
  await $.pumpAndTrySettle();
}

/// 创建情侣空间（从 couple-setup 页开始）
Future<void> _createCouple(
  PatrolIntegrationTester $, {
  String coupleName = kTestCoupleName,
}) async {
  // 等待跳转到 couple-setup 页
  await $.pumpAndTrySettle();

  // 点击「创建新的情侣空间」卡片
  await $('创建新的情侣空间').tap();
  await $.pumpAndTrySettle();

  // 填写情侣空间名称
  await enterTextAndDismissKeyboard($, const Key('create_couple_name'), coupleName);

  // 提交创建
  await $('创建空间').tap();
  await $.pumpAndTrySettle();

  // 创建成功后点击「进入首页」
  await $('进入首页').tap();
  await $.pumpAndTrySettle();
}
