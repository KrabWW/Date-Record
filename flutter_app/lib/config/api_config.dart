import 'dart:io';

/// API 配置
class ApiConfig {
  /// 生产环境服务器地址
  static const String _prodServer = 'http://8.140.227.83';

  /// 本地开发服务器地址（Android 模拟器使用 10.0.2.2 访问宿主机 localhost）
  static const String _localServer = 'http://10.0.2.2:3001';

  /// 是否使用本地服务器
  static const bool _useLocal = true;

  /// 当前服务器地址
  static String get _server => _useLocal ? _localServer : _prodServer;

  /// 基础 URL
  static String get baseUrl => '$_server/api';

  /// WebSocket URL (如果需要)
  static String get wsUrl => _useLocal ? 'ws://10.0.2.2:3001' : 'ws://8.140.227.83';

  /// 上传文件 URL
  static String get uploadUrl => '$baseUrl/upload';

  /// 获取完整的媒体文件 URL
  static String getMediaUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';

    // 如果已经是完整 URL，直接返回
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }

    // 构建完整 URL
    final serverUrl = _server;

    return '$serverUrl${relativeUrl.startsWith('/') ? relativeUrl : '/$relativeUrl'}';
  }
}
