import React, { useState, useEffect } from 'react';
import { mediaAPI } from '../services/api';
import { HardDrive, Crown, AlertTriangle } from 'lucide-react';

const StorageInfo = ({ className = '' }) => {
  const [storageInfo, setStorageInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadStorageInfo();
  }, []);

  const loadStorageInfo = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await mediaAPI.getStorageInfo();
      setStorageInfo(response.data);
    } catch (error) {
      console.error('Failed to load storage info:', error);
      setError('获取存储信息失败');
    } finally {
      setLoading(false);
    }
  };

  const formatStorage = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getStorageColor = (percentage) => {
    if (percentage < 50) return 'bg-green-500';
    if (percentage < 80) return 'bg-yellow-500';
    if (percentage < 95) return 'bg-orange-500';
    return 'bg-red-500';
  };

  const getStorageTextColor = (percentage) => {
    if (percentage < 50) return 'text-green-600';
    if (percentage < 80) return 'text-yellow-600';
    if (percentage < 95) return 'text-orange-600';
    return 'text-red-600';
  };

  if (loading) {
    return (
      <div className={`animate-pulse ${className}`}>
        <div className="bg-white rounded-lg p-4 shadow-sm border border-gray-200">
          <div className="h-4 bg-gray-200 rounded mb-3"></div>
          <div className="h-2 bg-gray-200 rounded mb-2"></div>
          <div className="h-3 bg-gray-200 rounded w-3/4"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`${className}`}>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-red-600 mr-2" />
            <div className="flex-1">
              <p className="text-red-600 text-sm">{error}</p>
              <button
                onClick={loadStorageInfo}
                className="text-red-600 text-sm underline hover:no-underline mt-1"
              >
                重试
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!storageInfo) return null;

  const { 
    isVip, 
    maxStorage, 
    usedStorage, 
    availableStorage, 
    usagePercentage, 
    limits 
  } = storageInfo;

  return (
    <div className={className}>
      <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-200">
        {/* 头部 */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center">
            <HardDrive className="w-5 h-5 text-gray-600 mr-2" />
            <h3 className="text-lg font-semibold text-gray-800">存储空间</h3>
          </div>
          {isVip && (
            <div className="flex items-center bg-gradient-to-r from-love-pink to-love-purple text-white px-3 py-1 rounded-full text-sm">
              <Crown className="w-4 h-4 mr-1" />
              VIP
            </div>
          )}
        </div>

        {/* 存储进度条 */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-600">已使用</span>
            <span className={`text-sm font-medium ${getStorageTextColor(usagePercentage)}`}>
              {formatStorage(usedStorage)} / {formatStorage(maxStorage)}
            </span>
          </div>
          
          <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
            <div 
              className={`h-full rounded-full transition-all duration-300 ${getStorageColor(usagePercentage)}`}
              style={{ width: `${Math.min(usagePercentage, 100)}%` }}
            />
          </div>
          
          <div className="flex justify-between items-center mt-2">
            <span className="text-xs text-gray-500">
              使用率 {usagePercentage}%
            </span>
            <span className="text-xs text-gray-500">
              剩余 {formatStorage(availableStorage)}
            </span>
          </div>

          {/* 警告信息 */}
          {usagePercentage >= 90 && (
            <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg">
              <div className="flex items-center">
                <AlertTriangle className="w-4 h-4 text-red-600 mr-2 flex-shrink-0" />
                <p className="text-red-600 text-sm">
                  存储空间即将用尽，请及时清理文件或升级VIP获得更大空间。
                </p>
              </div>
            </div>
          )}
        </div>

        {/* 限制信息 */}
        <div className="space-y-3">
          <h4 className="text-sm font-medium text-gray-800">当前限制</h4>
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-gray-50 rounded-lg p-3 text-center">
              <div className="text-xs text-gray-600 mb-1">单张照片</div>
              <div className="text-sm font-semibold text-gray-800">
                最大 {formatStorage(limits.photoSize)}
              </div>
            </div>
            <div className="bg-gray-50 rounded-lg p-3 text-center">
              <div className="text-xs text-gray-600 mb-1">单个视频</div>
              <div className="text-sm font-semibold text-gray-800">
                最大 {formatStorage(limits.videoSize)}
              </div>
            </div>
          </div>
          <div className="bg-gray-50 rounded-lg p-3 text-center">
            <div className="text-xs text-gray-600 mb-1">总存储空间</div>
            <div className="text-sm font-semibold text-gray-800">
              {formatStorage(maxStorage)}
            </div>
          </div>
        </div>

        {/* VIP升级提示 */}
        {!isVip && (
          <div className="mt-6 bg-gradient-to-r from-love-pink to-love-purple rounded-lg p-4 text-white">
            <div className="flex items-start">
              <Crown className="w-5 h-5 mr-3 mt-0.5 flex-shrink-0" />
              <div className="flex-1">
                <h4 className="font-semibold mb-2">升级VIP解锁更多空间</h4>
                <ul className="text-sm text-white/90 space-y-1 mb-3">
                  <li>• 10GB 总存储空间（当前 1GB）</li>
                  <li>• 单张照片最大 20MB（当前 10MB）</li>
                  <li>• 单个视频最大 500MB（当前 100MB）</li>
                  <li>• 优先技术支持</li>
                </ul>
                <button className="bg-white text-love-pink px-4 py-2 rounded-lg font-medium hover:bg-gray-50 transition-colors text-sm">
                  了解VIP特权
                </button>
              </div>
            </div>
          </div>
        )}

        {/* VIP到期提醒 */}
        {isVip && (
          <div className="mt-6 bg-green-50 border border-green-200 rounded-lg p-3">
            <div className="flex items-center">
              <Crown className="w-4 h-4 text-green-600 mr-2" />
              <div className="text-sm text-green-700">
                您当前是VIP用户，享受增强的存储空间和上传限制
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StorageInfo;