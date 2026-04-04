import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/media.dart';
import 'api_client.dart';

part 'media_service.g.dart';

/// 媒体服务 Provider
@riverpod
MediaService mediaService(MediaServiceRef ref) {
  return MediaService();
}

/// 媒体服务
class MediaService {
  final ApiClient _api = ApiClient();

  /// 上传照片
  Future<Media> uploadPhoto({
    required File file,
    required int coupleId,
    int? recordId,
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(file.path),
        'couple_id': coupleId,
        if (recordId != null) 'record_id': recordId,
        if (caption != null) 'caption': caption,
      });

      final response = await _api.upload('/upload/photo', data: formData);
      // 后端返回 { success, mediaId, fileUrl, fileType }
      return Media(
        id: response.data['mediaId'] as int,
        coupleId: coupleId,
        recordId: recordId,
        fileUrl: response.data['fileUrl'] as String,
        fileType: response.data['fileType'] as String? ?? 'photo',
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 通过 ImagePicker 上传照片
  Future<Media?> uploadPhotoFromPicker({
    required int coupleId,
    int? recordId,
    String? caption,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    return uploadPhoto(
      file: file,
      coupleId: coupleId,
      recordId: recordId,
      caption: caption,
    );
  }

  /// 上传视频
  Future<Media> uploadVideo({
    required File file,
    required int coupleId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(file.path),
        'couple_id': coupleId,
      });

      final response = await _api.upload('/upload/video', data: formData);
      // 后端返回 { success, mediaId, fileUrl, thumbnailUrl, fileType, duration }
      return Media(
        id: response.data['mediaId'] as int,
        coupleId: coupleId,
        fileUrl: response.data['fileUrl'] as String,
        thumbnailUrl: response.data['thumbnailUrl'] as String?,
        fileType: response.data['fileType'] as String? ?? 'video',
        duration: response.data['duration'] as int?,
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 通过 ImagePicker 上传视频
  Future<Media?> uploadVideoFromPicker({
    required int coupleId,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );

    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    return uploadVideo(
      file: file,
      coupleId: coupleId,
    );
  }

  /// 获取媒体文件列表
  Future<List<Media>> getMedia({int? recordId}) async {
    try {
      final path =
          recordId != null ? '/upload/media/$recordId' : '/upload/media';
      final response = await _api.get(path);

      // 后端返回 { data: [...] }
      final data = response.data['data'];
      if (data == null) return [];

      final mediaList = data is List ? data : (data is Map ? data['media'] as List? : null);
      return mediaList?.map((e) => Media.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除媒体文件
  Future<String> deleteMedia(int mediaId) async {
    try {
      final response = await _api.delete('/upload/media/$mediaId');
      return response.data['message'] ?? '删除成功';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取存储空间信息
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final response = await _api.get('/upload/storage-info');
      // 后端返回直接属性 { isVip, maxStorage, usedStorage, ... }
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
