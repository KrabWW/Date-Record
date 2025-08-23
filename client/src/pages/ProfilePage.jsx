import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { mediaAPI } from '../services/api';
import { 
  User, 
  Heart, 
  Settings, 
  List, 
  Users, 
  Database, 
  Gift,
  LogOut, 
  ChevronRight,
  Copy,
  Share2
} from 'lucide-react';

const ProfilePage = () => {
  const { user, couple, hasCouple, logout, getPartner } = useAuth();
  const [storageInfo, setStorageInfo] = useState(null);
  const [copying, setCopying] = useState(false);
  
  const partner = getPartner();

  useEffect(() => {
    loadStorageInfo();
  }, []);

  const loadStorageInfo = async () => {
    try {
      const response = await mediaAPI.getStorageInfo();
      setStorageInfo(response.data);
    } catch (error) {
      console.error('Failed to load storage info:', error);
    }
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  const copyInviteCode = async () => {
    if (!couple?.invite_code) return;
    
    setCopying(true);
    try {
      await navigator.clipboard.writeText(couple.invite_code);
      setTimeout(() => setCopying(false), 2000);
    } catch (error) {
      console.error('Failed to copy invite code:', error);
      setCopying(false);
    }
  };

  const handleLogout = async () => {
    if (confirm('确定要退出登录吗？')) {
      await logout();
    }
  };

  return (
    <div className="space-y-6">
      {/* 用户信息卡片 */}
      <div className="card">
        <div className="flex items-center">
          <div className="w-16 h-16 bg-gradient-to-br from-love-pink to-love-purple rounded-full flex items-center justify-center mr-4">
            <User className="w-8 h-8 text-white" />
          </div>
          <div className="flex-1">
            <h2 className="text-xl font-bold text-gray-800">{user?.name}</h2>
            <p className="text-gray-600 text-sm">{user?.email}</p>
            {storageInfo && (
              <div className="mt-2">
                <div className="flex items-center text-xs text-gray-500">
                  <Database className="w-3 h-3 mr-1" />
                  已用 {formatFileSize(storageInfo.usedStorage)} / {formatFileSize(storageInfo.maxStorage)}
                  {storageInfo.isVip && (
                    <span className="ml-2 px-2 py-0.5 bg-yellow-100 text-yellow-800 rounded text-xs">VIP</span>
                  )}
                </div>
                <div className="mt-1 w-full bg-gray-200 rounded-full h-1">
                  <div 
                    className="bg-love-pink h-1 rounded-full"
                    style={{ width: `${Math.min(storageInfo.usagePercentage, 100)}%` }}
                  ></div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* 情侣空间信息 */}
      {hasCouple && couple && (
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center">
              <Heart className="w-5 h-5 mr-2 text-love-pink" />
              情侣空间
            </h3>
          </div>
          
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-gray-600">空间名称</span>
              <span className="font-medium">{couple.couple_name}</span>
            </div>
            
            {partner && (
              <div className="flex justify-between items-center">
                <span className="text-gray-600">伴侣</span>
                <span className="font-medium">{partner.name}</span>
              </div>
            )}
            
            {couple.anniversary_date && (
              <div className="flex justify-between items-center">
                <span className="text-gray-600">纪念日</span>
                <span className="font-medium">
                  {new Date(couple.anniversary_date).toLocaleDateString('zh-CN')}
                </span>
              </div>
            )}
            
            {couple.invite_code && (
              <div className="flex justify-between items-center">
                <span className="text-gray-600">邀请码</span>
                <div className="flex items-center space-x-2">
                  <code className="bg-gray-100 px-2 py-1 rounded text-sm">
                    {couple.invite_code}
                  </code>
                  <button
                    onClick={copyInviteCode}
                    className="p-1 text-gray-500 hover:text-gray-700"
                    title="复制邀请码"
                  >
                    {copying ? (
                      <span className="text-xs text-green-600">已复制!</span>
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* 快速访问 */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">快速访问</h3>
        <div className="space-y-2">
          <Link
            to="/wishlist"
            className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center">
              <List className="w-5 h-5 mr-3 text-love-purple" />
              <span className="font-medium">愿望清单</span>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-400" />
          </Link>
          
          {!hasCouple && (
            <Link
              to="/couple-setup"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <Users className="w-5 h-5 mr-3 text-love-pink" />
                <span className="font-medium">创建情侣空间</span>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400" />
            </Link>
          )}
        </div>
      </div>

      {/* 设置选项 */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">设置</h3>
        <div className="space-y-2">
          <Link
            to="/settings"
            className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center">
              <Settings className="w-5 h-5 mr-3 text-gray-600" />
              <span className="font-medium">应用设置</span>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-400" />
          </Link>
          
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-red-50 transition-colors text-red-600"
          >
            <div className="flex items-center">
              <LogOut className="w-5 h-5 mr-3" />
              <span className="font-medium">退出登录</span>
            </div>
          </button>
        </div>
      </div>

      {/* VIP升级卡片（如果不是VIP用户） */}
      {storageInfo && !storageInfo.isVip && (
        <div className="card border-2 border-dashed border-yellow-300 bg-yellow-50">
          <div className="text-center">
            <Gift className="w-12 h-12 text-yellow-600 mx-auto mb-3" />
            <h3 className="text-lg font-semibold text-gray-800 mb-2">升级到VIP</h3>
            <p className="text-sm text-gray-600 mb-4">
              获得10GB存储空间，更大的上传文件限制，以及更多功能
            </p>
            <button className="btn-primary">
              立即升级
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProfilePage;