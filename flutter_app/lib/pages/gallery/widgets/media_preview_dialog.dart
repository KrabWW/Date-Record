import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/media.dart';

/// 媒体预览对话框
class MediaPreviewDialog extends StatefulWidget {
  final Media media;
  final List<Media> allMedia;
  final int initialIndex;
  final VoidCallback onDelete;

  const MediaPreviewDialog({
    super.key,
    required this.media,
    required this.allMedia,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  Media get _currentMedia => widget.allMedia[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializeMedia();
  }

  @override
  void didUpdateWidget(MediaPreviewDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.media.id != oldWidget.media.id) {
      _cleanupVideo();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (_currentMedia.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = ApiConfig.getMediaUrl(_currentMedia.fileUrl);

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      await _videoController!.play();
    } catch (e) {
      debugPrint('视频初始化失败: $e');
    }
  }

  void _cleanupVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  void _previousMedia() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializeMedia();
    }
  }

  void _nextMedia() {
    if (_currentIndex < widget.allMedia.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializeMedia();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _cleanupVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = _currentMedia.isPhoto;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 媒体内容
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < 0) {
                  _nextMedia();
                } else {
                  _previousMedia();
                }
              },
              child: isPhoto ? _buildPhotoContent() : _buildVideoContent(),
            ),
          ),

          // 顶部栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // 底部栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),

          // 左右导航按钮 (仅照片)
          if (isPhoto && widget.allMedia.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: _buildNavButton(
                icon: Icons.chevron_left,
                onTap: _currentIndex > 0 ? _previousMedia : null,
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: _buildNavButton(
                icon: Icons.chevron_right,
                onTap: _currentIndex < widget.allMedia.length - 1
                    ? _nextMedia
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    final imageUrl = ApiConfig.getMediaUrl(_currentMedia.fileUrl);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              _currentMedia.isPhoto ? Icons.photo_camera : Icons.videocam,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_formatDate(_currentMedia.createdAt)} · ${_formatFileSize(_currentMedia.fileSize)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            if (widget.allMedia.length > 1)
              Text(
                '${_currentIndex + 1} / ${widget.allMedia.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 视频
            if (_currentMedia.isVideo &&
                _isVideoInitialized &&
                _videoController != null)
              _VideoControls(controller: _videoController!),

            // 标题描述
            if (_currentMedia.caption != null &&
                _currentMedia.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _currentMedia.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 删除按钮
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '删除',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white24,
          size: 32,
        ),
      ),
    );
  }
}

/// 视频控制组件
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _showControls = true;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(() {});
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 进度条
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.lovePink,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppTheme.lovePink,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.position.inMilliseconds.toDouble(),
                min: 0,
                max: value.duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  widget.controller.seekTo(
                    Duration(milliseconds: value.toInt()),
                  );
                },
              ),
            ),

            // 时间和控制按钮
            Row(
              children: [
                Text(
                  _formatDuration(value.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(value.duration),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // 播放/暂停按钮
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
