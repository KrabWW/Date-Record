import React, { useState, useEffect } from 'react';
import { mediaAPI, utils } from '../services/api';
import { useAuth } from '../context/AuthContext';
import MediaUpload from '../components/MediaUpload';
import { Camera, Video, Upload, Grid, List, Calendar, Heart, Play, Plus } from 'lucide-react';

const GalleryPage = () => {
  const [media, setMedia] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // all, photos, videos
  const [viewMode, setViewMode] = useState('grid'); // grid, list
  const [selectedMedia, setSelectedMedia] = useState(null);
  const [showUpload, setShowUpload] = useState(false);
  const [stats, setStats] = useState({
    totalPhotos: 0,
    totalVideos: 0,
    totalSize: 0
  });
  
  const { couple } = useAuth();

  useEffect(() => {
    loadMedia();
  }, []);

  const loadMedia = async () => {
    try {
      setLoading(true);
      // 获取所有媒体文件
      const response = await mediaAPI.getMedia();
      const mediaList = response.data?.data || [];
      setMedia(mediaList);
      
      // 计算统计数据
      const photos = mediaList.filter(m => m.file_type === 'photo');
      const videos = mediaList.filter(m => m.file_type === 'video');
      const totalSize = mediaList.reduce((sum, m) => sum + (m.file_size || 0), 0);
      
      setStats({
        totalPhotos: photos.length,
        totalVideos: videos.length,
        totalSize: totalSize
      });
    } catch (error) {
      console.error('Failed to load media:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredMedia = media.filter(item => {
    switch (filter) {
      case 'photos':
        return item.file_type === 'photo';
      case 'videos':
        return item.file_type === 'video';
      default:
        return true;
    }
  });

  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatTotalSize = (bytes) => {
    if (!bytes) return '0 B';
    if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
  };

  const formatDuration = (seconds) => {
    if (!seconds) return '';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const handleDeleteMedia = async (mediaId) => {
    if (!confirm('确定要删除这个文件吗？')) return;

    try {
      await mediaAPI.deleteMedia(mediaId);
      loadMedia(); // 重新加载列表
    } catch (error) {
      console.error('Failed to delete media:', error);
      alert('删除失败，请稍后重试');
    }
  };

  const handleUploadSuccess = (uploadedMedia) => {
    // 刷新媒体列表
    loadMedia();
  };

  const getMediaUrl = (filePath) => {
    return utils.getImageUrl(filePath);
  };

  const renderMediaItem = (item, index) => {
    const isPhoto = item.file_type === 'photo';
    
    if (viewMode === 'grid') {
      return (
        <div
          key={item.id}
          className="relative aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:shadow-lg transition-shadow"
          onClick={() => setSelectedMedia(item)}
        >
          {isPhoto ? (
            <img
              src={getMediaUrl(item.file_url)}
              alt={item.caption}
              className="w-full h-full object-cover"
              loading="lazy"
            />
          ) : (
            <>
              <img
                src={getMediaUrl(item.thumbnail_url) || '/placeholder-video.jpg'}
                alt={item.caption}
                className="w-full h-full object-cover"
                loading="lazy"
              />
              <div className="absolute inset-0 bg-black bg-opacity-30 flex items-center justify-center">
                <div className="w-12 h-12 bg-white bg-opacity-80 rounded-full flex items-center justify-center">
                  <Play className="w-6 h-6 text-gray-800 ml-1" />
                </div>
              </div>
              {item.duration && (
                <div className="absolute bottom-2 right-2 bg-black bg-opacity-70 text-white text-xs px-2 py-1 rounded">
                  {formatDuration(item.duration)}
                </div>
              )}
            </>
          )}
          
          {/* 文件类型指示器 */}
          <div className="absolute top-2 left-2">
            {isPhoto ? (
              <Camera className="w-4 h-4 text-white drop-shadow" />
            ) : (
              <Video className="w-4 h-4 text-white drop-shadow" />
            )}
          </div>
        </div>
      );
    } else {
      // List view
      return (
        <div
          key={item.id}
          className="card-interactive cursor-pointer"
          onClick={() => setSelectedMedia(item)}
        >
          <div className="flex items-center">
            {/* 缩略图 */}
            <div className="w-16 h-16 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0 mr-4">
              {isPhoto ? (
                <img
                  src={getMediaUrl(item.file_url)}
                  alt={item.caption}
                  className="w-full h-full object-cover"
                  loading="lazy"
                />
              ) : (
                <div className="w-full h-full relative">
                  <img
                    src={getMediaUrl(item.thumbnail_url) || '/placeholder-video.jpg'}
                    alt={item.caption}
                    className="w-full h-full object-cover"
                    loading="lazy"
                  />
                  <div className="absolute inset-0 bg-black bg-opacity-30 flex items-center justify-center">
                    <Play className="w-4 h-4 text-white" />
                  </div>
                </div>
              )}
            </div>

            {/* 信息 */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center mb-1">
                {isPhoto ? (
                  <Camera className="w-4 h-4 text-love-pink mr-2" />
                ) : (
                  <Video className="w-4 h-4 text-love-purple mr-2" />
                )}
                <span className="text-sm font-medium text-gray-800">
                  {isPhoto ? '照片' : '视频'}
                  {item.duration && ` • ${formatDuration(item.duration)}`}
                </span>
              </div>
              
              {item.caption && (
                <p className="text-sm text-gray-600 mb-1 text-truncate">
                  {item.caption}
                </p>
              )}
              
              <div className="text-xs text-gray-500">
                <Calendar className="w-3 h-3 inline mr-1" />
                {formatDate(item.created_at)}
                <span className="mx-2">•</span>
                {formatFileSize(item.file_size)}
              </div>
            </div>

            {/* 删除按钮 */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                handleDeleteMedia(item.id);
              }}
              className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-gray-100"
            >
              🗑️
            </button>
          </div>
        </div>
      );
    }
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-display font-bold text-gray-800">
            相册
          </h1>
        </div>
        
        <div className="grid grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="aspect-square bg-gray-200 rounded-lg animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和统计 */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h1 className="text-2xl font-display font-bold text-gray-800">
            相册
          </h1>
          
          <div className="flex items-center space-x-2">
            {/* 上传按钮 */}
            <button
              onClick={() => setShowUpload(!showUpload)}
              className={`p-2 rounded-full transition-all duration-200 ${
                showUpload
                  ? 'bg-love-pink text-white'
                  : 'bg-love-pink text-white hover:bg-love-pink-dark'
              }`}
            >
              <Plus className="w-5 h-5" />
            </button>
            
            {/* 视图切换 */}
            <div className="flex bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded ${
                  viewMode === 'grid' 
                    ? 'bg-white shadow text-love-pink' 
                    : 'text-gray-600 hover:text-gray-800'
                }`}
              >
                <Grid className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 rounded ${
                  viewMode === 'list' 
                    ? 'bg-white shadow text-love-pink' 
                    : 'text-gray-600 hover:text-gray-800'
                }`}
              >
                <List className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* 统计信息 */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          <div className="card text-center">
            <Camera className="w-6 h-6 text-love-pink mx-auto mb-2" />
            <div className="text-lg font-bold text-gray-800">{stats.totalPhotos}</div>
            <div className="text-sm text-gray-600">照片</div>
          </div>
          <div className="card text-center">
            <Video className="w-6 h-6 text-love-purple mx-auto mb-2" />
            <div className="text-lg font-bold text-gray-800">{stats.totalVideos}</div>
            <div className="text-sm text-gray-600">视频</div>
          </div>
          <div className="card text-center">
            <Upload className="w-6 h-6 text-gray-600 mx-auto mb-2" />
            <div className="text-lg font-bold text-gray-800">{formatTotalSize(stats.totalSize)}</div>
            <div className="text-sm text-gray-600">总大小</div>
          </div>
        </div>
      </div>

      {/* 过滤标签 */}
      <div className="flex space-x-2 overflow-x-auto">
        {[
          { key: 'all', label: '全部', count: media.length, icon: Heart },
          { key: 'photos', label: '照片', count: stats.totalPhotos, icon: Camera },
          { key: 'videos', label: '视频', count: stats.totalVideos, icon: Video }
        ].map(({ key, label, count, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 flex items-center ${
              filter === key
                ? 'bg-love-pink text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            <Icon className="w-4 h-4 mr-1" />
            {label} ({count})
          </button>
        ))}
      </div>

      {/* 上传组件 */}
      {showUpload && (
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-800">上传照片和视频</h3>
            <button
              onClick={() => setShowUpload(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <Plus className="w-5 h-5 transform rotate-45" />
            </button>
          </div>
          <MediaUpload
            coupleId={couple?.id}
            onUploadSuccess={handleUploadSuccess}
          />
        </div>
      )}

      {/* 媒体内容 */}
      {filteredMedia.length > 0 ? (
        <div className={
          viewMode === 'grid' 
            ? 'grid grid-cols-3 gap-4' 
            : 'space-y-4'
        }>
          {filteredMedia.map(renderMediaItem)}
        </div>
      ) : (
        <div className="card text-center py-12">
          <Camera className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-800 mb-2">
            {filter === 'photos' 
              ? '还没有照片' 
              : filter === 'videos'
                ? '还没有视频'
                : '还没有媒体文件'
            }
          </h3>
          <p className="text-gray-600 mb-6">
            开始记录你们的美好时光，上传照片和视频
          </p>
          <button
            onClick={() => window.location.href = '/records'}
            className="btn-primary"
          >
            去添加记录
          </button>
        </div>
      )}

      {/* 媒体预览模态框 */}
      {selectedMedia && (
        <div className="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center p-4 z-50">
          <div className="max-w-4xl max-h-full flex flex-col">
            {/* 关闭按钮 */}
            <div className="flex justify-between items-center mb-4">
              <div className="flex items-center text-white">
                {selectedMedia.file_type === 'photo' ? (
                  <Camera className="w-5 h-5 mr-2" />
                ) : (
                  <Video className="w-5 h-5 mr-2" />
                )}
                <span className="text-sm">
                  {formatDate(selectedMedia.created_at)} • {formatFileSize(selectedMedia.file_size)}
                </span>
              </div>
              <button
                onClick={() => setSelectedMedia(null)}
                className="text-white hover:text-gray-300 text-2xl"
              >
                ✕
              </button>
            </div>

            {/* 媒体内容 */}
            <div className="flex-1 flex items-center justify-center">
              {selectedMedia.file_type === 'photo' ? (
                <img
                  src={getMediaUrl(selectedMedia.file_url)}
                  alt={selectedMedia.caption}
                  className="max-w-full max-h-full object-contain"
                />
              ) : (
                <video
                  src={getMediaUrl(selectedMedia.file_url)}
                  controls
                  className="max-w-full max-h-full"
                  autoPlay
                />
              )}
            </div>

            {/* 标题描述 */}
            {selectedMedia.caption && (
              <div className="mt-4 text-center text-white">
                <p className="text-lg">{selectedMedia.caption}</p>
              </div>
            )}

            {/* 操作按钮 */}
            <div className="flex justify-center mt-4 space-x-4">
              <button
                onClick={() => handleDeleteMedia(selectedMedia.id)}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                删除文件
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default GalleryPage;