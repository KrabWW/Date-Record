import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../config/constants.dart';
import '../../models/media.dart';
import '../../providers/couple_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/storage_info.dart';
import 'widgets/media_preview_dialog.dart';
import 'widgets/media_upload_sheet.dart';

/// 媒体过滤类型
enum MediaFilter {
  all,
  photos,
  videos,
}

/// 视图模式
enum ViewMode {
  grid,
  list,
}

/// 相册页面
class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  // 状态
  List<Media> _media = [];
  MediaFilter _filter = MediaFilter.all;
  ViewMode _viewMode = ViewMode.grid;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _storageInfo;

  // 上传状态
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final couple = ref.read(currentCoupleProvider).value;
      if (couple == null) {
        setState(() {
          _isLoading = false;
          _error = '请先创建情侣空间';
        });
        return;
      }

      // 并行加载媒体和存储信息
      final results = await Future.wait([
        ref.read(mediaServiceProvider).getMedia(),
        ref.read(mediaServiceProvider).getStorageInfo(),
      ]);

      setState(() {
        _media = results[0] as List<Media>;
        _storageInfo = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// 刷新数据
  Future<void> _refresh() async {
    await _loadData();
  }

  /// 删除媒体
  Future<void> _deleteMedia(Media media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这张${media.isPhoto ? '照片' : '视频'}吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(mediaServiceProvider).deleteMedia(media.id);
      setState(() {
        _media.remove(media);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 打开上传选项
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaUploadSheet(
        onUploadPhoto: _pickAndUploadPhoto,
        onUploadVideo: _pickAndUploadVideo,
        isUploading: _isUploading,
        uploadProgress: _uploadProgress,
      ),
    );
  }

  /// 拍照或选择照片
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final couple = ref.read(currentCoupleProvider).value;
    if (couple == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final file = File(pickedFile.path);

      // 检查文件大小（10MB 限制）
      final fileSize = await file.length();
      const maxPhotoSize = 10 * 1024 * 1024;
      if (fileSize > maxPhotoSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片大小不能超过 10MB')),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.5;
      });

      final uploaded = await ref.read(mediaServiceProvider).uploadPhoto(
            file: file,
            coupleId: couple.id,
          );

      setState(() {
        _uploadProgress = 1.0;
        _media.insert(0, uploaded);
        _isUploading = false;
      });

      if (mounted) {
        Navigator.pop(context); // 关闭 bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  /// 选择视频
  Future<void> _pickAndUploadVideo() async {
    final couple = ref.read(currentCoupleProvider).value;
    if (couple == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final file = File(pickedFile.path);

      // 检查文件大小（100MB 限制）
      final fileSize = await file.length();
      const maxVideoSize = 100 * 1024 * 1024;
      if (fileSize > maxVideoSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('视频大小不能超过 100MB')),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.5;
      });

      final uploaded = await ref.read(mediaServiceProvider).uploadVideo(
            file: file,
            coupleId: couple.id,
          );

      setState(() {
        _uploadProgress = 1.0;
        _media.insert(0, uploaded);
        _isUploading = false;
      });

      if (mounted) {
        Navigator.pop(context); // 关闭 bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  /// 打开媒体预览
  void _openMediaPreview(Media media, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MediaPreviewDialog(
        media: media,
        allMedia: _getFilteredMedia(),
        initialIndex: index,
        onDelete: () => _deleteMedia(media),
      ),
    );
  }

  /// 获取过滤后的媒体列表
  List<Media> _getFilteredMedia() {
    switch (_filter) {
      case MediaFilter.photos:
        return _media.where((m) => m.isPhoto).toList();
      case MediaFilter.videos:
        return _media.where((m) => m.isVideo).toList();
      case MediaFilter.all:
        return _media;
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int? bytes) {
    if (bytes == null) return '0 B';
    return StorageLimits.formatStorage(bytes);
  }

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final secsStr = secs.toString().padLeft(2, '0');
    return '$mins:$secsStr';
  }

  /// 获取统计数据
  Map<String, int> _getStats() {
    final photos = _media.where((m) => m.isPhoto).length;
    final videos = _media.where((m) => m.isVideo).length;
    final totalSize = _media.fold<int>(0, (sum, m) => sum + (m.fileSize ?? 0));
    return {
      'photos': photos,
      'videos': videos,
      'totalSize': totalSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(currentCoupleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('相册'),
        actions: [
          // 视图切换
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _viewMode == ViewMode.grid,
                  onTap: () => setState(() => _viewMode = ViewMode.grid),
                ),
                _ViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: _viewMode == ViewMode.list,
                  onTap: () => setState(() => _viewMode = ViewMode.list),
                ),
              ],
            ),
          ),
        ],
      ),
      body: couple.when(
        data: (couple) {
          if (couple == null) {
            return const Center(
              child: Text('请先创建情侣空间'),
            );
          }

          return _buildContent();
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const Center(
          child: Text('加载失败'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showUploadOptions,
        backgroundColor: AppTheme.lovePink,
        foregroundColor: Colors.white,
        icon: _isUploading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  value: _uploadProgress,
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isUploading ? '上传中...' : '上传'),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/records');
            case 2:
              context.go('/gallery');
            case 3:
              context.go('/profile');
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final filteredMedia = _getFilteredMedia();
    final stats = _getStats();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          // 统计信息
          SliverToBoxAdapter(
            child: _StatsBar(
              photoCount: stats['photos']!,
              videoCount: stats['videos']!,
              totalSize: stats['totalSize']!,
            ),
          ),

          // 过滤 chips
          SliverToBoxAdapter(
            child: _FilterChips(
              currentFilter: _filter,
              photoCount: stats['photos']!,
              videoCount: stats['videos']!,
              totalCount: _media.length,
              onFilterChanged: (filter) =>
                  setState(() => _filter = filter),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // 媒体内容
          filteredMedia.isEmpty
              ? _buildEmptyState()
              : _buildMediaGrid(filteredMedia),

          // 存储信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _storageInfo != null
                  ? StorageInfoBar(
                      usedStorage: _storageInfo!['used_storage'] ?? 0,
                      maxStorage: _storageInfo!['max_storage'],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => Container(
        color: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error ?? '加载失败'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;

    switch (_filter) {
      case MediaFilter.photos:
        title = '还没有照片';
        subtitle = '开始记录你们的美好时光';
        icon = Icons.photo_camera_outlined;
        break;
      case MediaFilter.videos:
        title = '还没有视频';
        subtitle = '拍摄视频记录精彩瞬间';
        icon = Icons.videocam_outlined;
        break;
      default:
        title = '相册空空如也';
        subtitle = '上传照片和视频，开始记录美好回忆';
        icon = Icons.photo_library_outlined;
    }

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<Media> media) {
    if (_viewMode == ViewMode.grid) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = media[index];
            return _MediaGridItem(
              media: item,
              onTap: () => _openMediaPreview(item, index),
              onLongPress: () => _deleteMedia(item),
              formatDuration: _formatDuration,
            );
          },
          childCount: media.length,
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = media[index];
            return _MediaListItem(
              media: item,
              onTap: () => _openMediaPreview(item, index),
              onDelete: () => _deleteMedia(item),
              formatDuration: _formatDuration,
              formatFileSize: _formatFileSize,
            );
          },
          childCount: media.length,
        ),
      );
    }
  }
}

/// 视图切换按钮
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppTheme.lovePink : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

/// 统计信息条
class _StatsBar extends StatelessWidget {
  final int photoCount;
  final int videoCount;
  final int totalSize;

  const _StatsBar({
    required this.photoCount,
    required this.videoCount,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.photo_camera_rounded,
            label: '照片',
            value: photoCount.toString(),
            color: AppTheme.lovePink,
          ),
          Container(
            height: 24,
            width: 1,
            color: AppTheme.divider,
          ),
          _StatItem(
            icon: Icons.videocam_rounded,
            label: '视频',
            value: videoCount.toString(),
            color: AppTheme.lovePurple,
          ),
          Container(
            height: 24,
            width: 1,
            color: AppTheme.divider,
          ),
          _StatItem(
            icon: Icons.storage_rounded,
            label: '总计',
            value: StorageLimits.formatStorage(totalSize),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 过滤 chips
class _FilterChips extends StatelessWidget {
  final MediaFilter currentFilter;
  final int photoCount;
  final int videoCount;
  final int totalCount;
  final ValueChanged<MediaFilter> onFilterChanged;

  const _FilterChips({
    required this.currentFilter,
    required this.photoCount,
    required this.videoCount,
    required this.totalCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: '全部',
            count: totalCount,
            isSelected: currentFilter == MediaFilter.all,
            onTap: () => onFilterChanged(MediaFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '照片',
            count: photoCount,
            isSelected: currentFilter == MediaFilter.photos,
            onTap: () => onFilterChanged(MediaFilter.photos),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '视频',
            count: videoCount,
            isSelected: currentFilter == MediaFilter.videos,
            onTap: () => onFilterChanged(MediaFilter.videos),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lovePink : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 网格视图媒体项
class _MediaGridItem extends StatelessWidget {
  final Media media;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String Function(int?) formatDuration;

  const _MediaGridItem({
    required this.media,
    required this.onTap,
    required this.onLongPress,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isPhoto = media.isPhoto;
    final imageUrl = ApiConfig.getMediaUrl(isPhoto ? media.fileUrl : media.thumbnailUrl);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: Icon(
                isPhoto ? Icons.broken_image : Icons.videocam_off,
                color: Colors.grey.shade400,
              ),
            ),
          ),

          // 视频播放覆盖层
          if (!isPhoto)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              ),
            ),

          // 视频时长标签
          if (!isPhoto && media.duration != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatDuration(media.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // 文件类型指示器
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                isPhoto ? Icons.photo_camera : Icons.videocam,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 列表视图媒体项
class _MediaListItem extends StatelessWidget {
  final Media media;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(int?) formatDuration;
  final String Function(int?) formatFileSize;

  const _MediaListItem({
    required this.media,
    required this.onTap,
    required this.onDelete,
    required this.formatDuration,
    required this.formatFileSize,
  });

  @override
  Widget build(BuildContext context) {
    final isPhoto = media.isPhoto;
    final imageUrl = ApiConfig.getMediaUrl(isPhoto ? media.fileUrl : media.thumbnailUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            isPhoto ? Icons.broken_image : Icons.videocam_off,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (!isPhoto)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPhoto ? Icons.photo_camera : Icons.videocam,
                          size: 16,
                          color: isPhoto ? AppTheme.lovePink : AppTheme.lovePurple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPhoto ? '照片' : '视频',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (!isPhoto && media.duration != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${formatDuration(media.duration)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (media.caption != null && media.caption!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        media.caption!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(media.createdAt)} · ${formatFileSize(media.fileSize)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.grey,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}
