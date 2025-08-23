import React, { useState, useEffect } from 'react';
import { mediaAPI, utils } from '../services/api';
import { Play, X, Trash2, Download, Calendar, Eye } from 'lucide-react';

const MediaGallery = ({ recordId, coupleId, className = '' }) => {
  const [media, setMedia] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedMedia, setSelectedMedia] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    loadMedia();
  }, [recordId, coupleId]);

  const loadMedia = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await mediaAPI.getMedia(recordId);
      setMedia(response.data?.data || []);
    } catch (error) {
      console.error('Failed to load media:', error);
      setError('加载媒体文件失败');
    } finally {
      setLoading(false);
    }
  };

  const deleteMedia = async (mediaId, event) => {
    event.stopPropagation();
    
    if (!confirm('确定要删除这个文件吗？')) return;

    try {
      await mediaAPI.deleteMedia(mediaId);
      setMedia(media.filter(item => item.id !== mediaId));
      
      // 如果删除的是当前选中的媒体，关闭预览
      if (selectedMedia?.id === mediaId) {
        setSelectedMedia(null);
      }
    } catch (error) {
      console.error('Failed to delete media:', error);
      alert('删除失败，请重试');
    }
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
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
      month: 'short',
      day: 'numeric'
    });
  };

  const getMediaUrl = (filePath) => {
    return utils.getImageUrl(filePath);
  };

  if (loading) {
    return (
      <div className={`${className}`}>
        <div className="grid grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="aspect-square bg-gray-200 rounded-lg animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`text-center py-8 ${className}`}>
        <p className="text-red-600 mb-4">{error}</p>
        <button
          onClick={loadMedia}
          className="btn-primary"
        >
          重试
        </button>
      </div>
    );
  }

  return (
    <div className={`${className}`}>
      {media.length > 0 ? (
        <div className="grid grid-cols-3 gap-4">
          {media.map((item) => (
            <div
              key={item.id}
              className="relative aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer group hover:shadow-lg transition-shadow"
              onClick={() => setSelectedMedia(item)}
            >
              {item.file_type === 'photo' ? (
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
                    <div className="w-12 h-12 bg-white bg-opacity-90 rounded-full flex items-center justify-center">
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
              
              {/* 悬浮操作按钮 */}
              <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={(e) => deleteMedia(item.id, e)}
                  className="w-8 h-8 bg-red-600 text-white rounded-full flex items-center justify-center hover:bg-red-700 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
              
              {/* 文件信息 */}
              <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <div className="text-white text-xs">
                  <div className="flex items-center justify-between">
                    <span>{formatFileSize(item.file_size)}</span>
                    <div className="flex items-center">
                      <Calendar className="w-3 h-3 mr-1" />
                      {formatDate(item.created_at)}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-500">
          <Eye className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <p>暂无媒体文件</p>
        </div>
      )}

      {/* 媒体预览模态框 */}
      {selectedMedia && (
        <div className="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center p-4 z-50">
          <div className="max-w-4xl max-h-full flex flex-col">
            {/* 头部操作栏 */}
            <div className="flex justify-between items-center mb-4 text-white">
              <div className="flex items-center space-x-4">
                <div className="flex items-center text-sm">
                  <Calendar className="w-4 h-4 mr-1" />
                  {new Date(selectedMedia.created_at).toLocaleDateString('zh-CN')}
                </div>
                <div className="text-sm">
                  {formatFileSize(selectedMedia.file_size)}
                </div>
                {selectedMedia.file_type === 'video' && selectedMedia.duration && (
                  <div className="text-sm">
                    时长: {formatDuration(selectedMedia.duration)}
                  </div>
                )}
              </div>
              
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => {
                    const link = document.createElement('a');
                    link.href = getMediaUrl(selectedMedia.file_url);
                    link.download = selectedMedia.file_url.split('/').pop();
                    link.click();
                  }}
                  className="p-2 text-white hover:text-gray-300 rounded-lg hover:bg-white hover:bg-opacity-10"
                  title="下载"
                >
                  <Download className="w-5 h-5" />
                </button>
                <button
                  onClick={(e) => deleteMedia(selectedMedia.id, e)}
                  className="p-2 text-white hover:text-red-400 rounded-lg hover:bg-white hover:bg-opacity-10"
                  title="删除"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
                <button
                  onClick={() => setSelectedMedia(null)}
                  className="p-2 text-white hover:text-gray-300 rounded-lg hover:bg-white hover:bg-opacity-10"
                  title="关闭"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
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

            {/* 底部描述 */}
            {selectedMedia.caption && (
              <div className="mt-4 text-center text-white">
                <p className="text-lg">{selectedMedia.caption}</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default MediaGallery;