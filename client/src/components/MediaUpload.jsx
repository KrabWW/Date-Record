import React, { useState, useRef } from 'react';
import { mediaAPI } from '../services/api';
import { Upload, Camera, Video, X, Check, AlertCircle } from 'lucide-react';

const MediaUpload = ({ recordId, coupleId, onUploadSuccess }) => {
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState([]);
  const [dragOver, setDragOver] = useState(false);
  const [error, setError] = useState('');
  const fileInputRef = useRef(null);

  // 文件验证
  const validateFile = (file) => {
    const maxSizes = {
      photo: 20 * 1024 * 1024, // 20MB (VIP限制，实际限制由后端根据用户状态确定)
      video: 500 * 1024 * 1024, // 500MB
    };

    const supportedTypes = {
      photo: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
      video: ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo'],
    };

    const fileType = file.type.startsWith('image/') ? 'photo' : 'video';
    
    if (!supportedTypes[fileType].includes(file.type)) {
      throw new Error(`不支持的文件类型: ${file.type}`);
    }

    if (file.size > maxSizes[fileType]) {
      throw new Error(`文件太大，${fileType === 'photo' ? '图片' : '视频'}最大${maxSizes[fileType] / (1024 * 1024)}MB`);
    }

    return fileType;
  };

  // 处理文件上传
  const handleFileUpload = async (files) => {
    if (!files || files.length === 0) return;

    setUploading(true);
    setError('');
    const filesArray = Array.from(files);
    const progressArray = filesArray.map((file, index) => ({
      id: index,
      name: file.name,
      progress: 0,
      status: 'pending', // pending, uploading, success, error
      error: null
    }));
    setUploadProgress(progressArray);

    try {
      for (let i = 0; i < filesArray.length; i++) {
        const file = filesArray[i];
        
        // 更新状态为上传中
        setUploadProgress(prev => prev.map((item, idx) => 
          idx === i ? { ...item, status: 'uploading', progress: 0 } : item
        ));

        try {
          const fileType = validateFile(file);
          const formData = new FormData();
          formData.append(fileType, file);
          
          if (recordId) formData.append('record_id', recordId);
          if (coupleId) formData.append('couple_id', coupleId);

          // 上传文件
          const uploadAPI = fileType === 'photo' ? mediaAPI.uploadPhoto : mediaAPI.uploadVideo;
          const response = await uploadAPI(formData);

          // 更新状态为成功
          setUploadProgress(prev => prev.map((item, idx) => 
            idx === i ? { ...item, status: 'success', progress: 100 } : item
          ));

          // 通知父组件上传成功
          if (onUploadSuccess) {
            onUploadSuccess({
              ...response.data,
              file: file,
              fileType: fileType
            });
          }
        } catch (error) {
          console.error(`Upload failed for ${file.name}:`, error);
          
          // 更新状态为失败
          setUploadProgress(prev => prev.map((item, idx) => 
            idx === i ? { 
              ...item, 
              status: 'error', 
              error: error.response?.data?.error || error.message || '上传失败'
            } : item
          ));
        }
      }
    } catch (error) {
      setError(error.message || '上传失败，请重试');
    } finally {
      setUploading(false);
      // 3秒后清除进度信息
      setTimeout(() => {
        setUploadProgress([]);
      }, 3000);
    }
  };

  // 拖拽处理
  const handleDragOver = (e) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setDragOver(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files);
    handleFileUpload(files);
  };

  // 点击上传
  const handleFileSelect = (e) => {
    const files = Array.from(e.target.files);
    handleFileUpload(files);
  };

  const triggerFileSelect = (accept = '*') => {
    if (fileInputRef.current) {
      fileInputRef.current.accept = accept;
      fileInputRef.current.click();
    }
  };

  return (
    <div className="media-upload space-y-4">
      {/* 上传区域 */}
      <div
        className={`border-2 border-dashed rounded-lg p-8 text-center transition-all cursor-pointer ${
          dragOver 
            ? 'border-love-pink bg-love-pink bg-opacity-5' 
            : uploading
              ? 'border-gray-300 bg-gray-50 cursor-not-allowed'
              : 'border-gray-300 hover:border-love-pink hover:bg-gray-50'
        }`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => !uploading && triggerFileSelect('image/*,video/*')}
      >
        <input
          type="file"
          ref={fileInputRef}
          multiple
          accept="image/*,video/*"
          onChange={handleFileSelect}
          className="hidden"
        />

        {uploading ? (
          <div className="space-y-3">
            <div className="w-12 h-12 mx-auto border-4 border-love-pink border-t-transparent rounded-full animate-spin"></div>
            <p className="text-gray-600">上传中...</p>
          </div>
        ) : (
          <div className="space-y-4">
            <Upload className="w-12 h-12 mx-auto text-gray-400" />
            <div>
              <p className="text-lg font-medium text-gray-700 mb-2">
                点击或拖拽上传照片和视频
              </p>
              <p className="text-sm text-gray-500">
                支持 JPG, PNG, GIF, WebP, MP4, WebM 等格式
              </p>
            </div>
          </div>
        )}
      </div>

      {/* 快速操作按钮 */}
      {!uploading && (
        <div className="flex space-x-4">
          <button 
            className="flex-1 btn-secondary flex items-center justify-center" 
            onClick={() => triggerFileSelect('image/*')}
          >
            <Camera className="w-4 h-4 mr-2" />
            选择照片
          </button>
          <button 
            className="flex-1 btn-secondary flex items-center justify-center" 
            onClick={() => triggerFileSelect('video/*')}
          >
            <Video className="w-4 h-4 mr-2" />
            选择视频
          </button>
        </div>
      )}

      {/* 错误信息 */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 flex items-center">
          <AlertCircle className="w-5 h-5 text-red-600 mr-2 flex-shrink-0" />
          <p className="text-red-600 text-sm">{error}</p>
          <button
            onClick={() => setError('')}
            className="ml-auto text-red-400 hover:text-red-600"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* 上传进度 */}
      {uploadProgress.length > 0 && (
        <div className="space-y-2">
          <h4 className="text-sm font-medium text-gray-700">上传进度</h4>
          {uploadProgress.map((item) => (
            <div key={item.id} className="bg-gray-50 rounded-lg p-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-gray-700 truncate">
                  {item.name}
                </span>
                <div className="flex items-center ml-2">
                  {item.status === 'uploading' && (
                    <div className="w-4 h-4 border-2 border-love-pink border-t-transparent rounded-full animate-spin"></div>
                  )}
                  {item.status === 'success' && (
                    <Check className="w-4 h-4 text-green-600" />
                  )}
                  {item.status === 'error' && (
                    <AlertCircle className="w-4 h-4 text-red-600" />
                  )}
                </div>
              </div>
              
              {item.status === 'uploading' && (
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-love-pink h-2 rounded-full transition-all duration-300" 
                    style={{ width: `${item.progress}%` }}
                  ></div>
                </div>
              )}
              
              {item.status === 'error' && (
                <p className="text-xs text-red-600 mt-1">{item.error}</p>
              )}
              
              {item.status === 'success' && (
                <p className="text-xs text-green-600 mt-1">上传成功</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default MediaUpload;