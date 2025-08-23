import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { User, Heart, Shield, HardDrive, Crown, LogOut, Copy, Check, Edit, Save } from 'lucide-react';

const SettingsPage = () => {
  const { user, couple, logout, updateProfile, getPartner } = useAuth();
  const [activeTab, setActiveTab] = useState('profile');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ type: '', content: '' });
  const [copied, setCopied] = useState(false);
  
  const [profileData, setProfileData] = useState({
    name: user?.name || '',
    email: user?.email || ''
  });
  const [isEditingProfile, setIsEditingProfile] = useState(false);

  const partner = getPartner();

  const showMessage = (type, content) => {
    setMessage({ type, content });
    setTimeout(() => setMessage({ type: '', content: '' }), 3000);
  };

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    if (!profileData.name.trim()) {
      showMessage('error', '姓名不能为空');
      return;
    }

    setLoading(true);
    try {
      const result = await updateProfile(profileData);
      if (result.success) {
        setIsEditingProfile(false);
        showMessage('success', '个人信息更新成功');
      } else {
        showMessage('error', result.error || '更新失败');
      }
    } catch (error) {
      showMessage('error', '更新失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  const copyInviteCode = async () => {
    if (!couple?.invite_code) return;
    
    try {
      await navigator.clipboard.writeText(couple.invite_code);
      setCopied(true);
      showMessage('success', '邀请码已复制到剪贴板');
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      // 降级方案
      const textArea = document.createElement('textarea');
      textArea.value = couple.invite_code;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      setCopied(true);
      showMessage('success', '邀请码已复制');
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleLogout = async () => {
    if (confirm('确定要退出登录吗？')) {
      await logout();
    }
  };

  const getDaysTogether = () => {
    if (!couple?.anniversary_date) return 0;
    const anniversaryDate = new Date(couple.anniversary_date);
    const today = new Date();
    const diffTime = Math.abs(today - anniversaryDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  const tabs = [
    { id: 'profile', label: '个人信息', icon: User },
    { id: 'couple', label: '情侣空间', icon: Heart },
    { id: 'storage', label: '存储空间', icon: HardDrive },
    { id: 'privacy', label: '隐私安全', icon: Shield },
  ];

  const renderProfileTab = () => (
    <div className="space-y-6">
      <div className="card">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-gray-800">个人信息</h3>
          {!isEditingProfile && (
            <button
              onClick={() => setIsEditingProfile(true)}
              className="btn-secondary flex items-center"
            >
              <Edit className="w-4 h-4 mr-1" />
              编辑
            </button>
          )}
        </div>

        {isEditingProfile ? (
          <form onSubmit={handleUpdateProfile} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                姓名
              </label>
              <input
                type="text"
                value={profileData.name}
                onChange={(e) => setProfileData(prev => ({ ...prev, name: e.target.value }))}
                className="input-field"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                邮箱
              </label>
              <input
                type="email"
                value={profileData.email}
                className="input-field bg-gray-50"
                disabled
              />
              <p className="text-xs text-gray-500 mt-1">邮箱地址不可修改</p>
            </div>

            <div className="flex space-x-4">
              <button
                type="submit"
                disabled={loading}
                className="btn-primary flex items-center disabled:opacity-50"
              >
                <Save className="w-4 h-4 mr-1" />
                {loading ? '保存中...' : '保存'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setIsEditingProfile(false);
                  setProfileData({ name: user?.name || '', email: user?.email || '' });
                }}
                className="btn-secondary"
              >
                取消
              </button>
            </div>
          </form>
        ) : (
          <div className="space-y-4">
            <div className="flex items-center">
              <div className="w-16 h-16 bg-gradient-to-br from-love-pink to-love-purple rounded-full flex items-center justify-center mr-4">
                <span className="text-white text-xl font-bold">
                  {user?.name?.charAt(0) || 'U'}
                </span>
              </div>
              <div>
                <h4 className="text-lg font-semibold text-gray-800">{user?.name}</h4>
                <p className="text-gray-600">{user?.email}</p>
                <p className="text-sm text-gray-500">
                  加入时间：{new Date(user?.created_at).toLocaleDateString('zh-CN')}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 账户操作 */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">账户操作</h3>
        <div className="space-y-3">
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center py-3 px-4 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors"
          >
            <LogOut className="w-4 h-4 mr-2" />
            退出登录
          </button>
        </div>
      </div>
    </div>
  );

  const renderCoupleTab = () => (
    <div className="space-y-6">
      {couple ? (
        <div className="card">
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-2">
              {couple.couple_name}
            </h3>
            <div className="flex items-center text-love-pink">
              <Heart className="w-5 h-5 mr-2" />
              <span>在一起第 {getDaysTogether()} 天</span>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                成员信息
              </label>
              <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                <div className="flex items-center">
                  <div className="w-8 h-8 bg-love-pink rounded-full flex items-center justify-center mr-3">
                    <span className="text-white text-sm font-bold">
                      {user?.name?.charAt(0)}
                    </span>
                  </div>
                  <div>
                    <p className="font-medium">{user?.name}</p>
                    <p className="text-sm text-gray-600">创建者</p>
                  </div>
                </div>
                
                {partner ? (
                  <div className="flex items-center">
                    <div className="w-8 h-8 bg-love-purple rounded-full flex items-center justify-center mr-3">
                      <span className="text-white text-sm font-bold">
                        {partner.name?.charAt(0)}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium">{partner.name}</p>
                      <p className="text-sm text-gray-600">伴侣</p>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-4 text-gray-500">
                    等待伴侣加入...
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                邀请码
              </label>
              <div className="flex items-center bg-gray-50 rounded-lg p-4">
                <code className="flex-1 text-lg font-mono font-bold text-love-pink tracking-wider">
                  {couple.invite_code}
                </code>
                <button
                  onClick={copyInviteCode}
                  className="ml-4 p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100"
                >
                  {copied ? <Check className="w-5 h-5 text-green-600" /> : <Copy className="w-5 h-5" />}
                </button>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                分享给您的伴侣，让他们加入这个空间
              </p>
            </div>

            {couple.anniversary_date && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  纪念日
                </label>
                <p className="bg-gray-50 rounded-lg p-4">
                  {new Date(couple.anniversary_date).toLocaleDateString('zh-CN', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </p>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="card text-center py-12">
          <Heart className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-800 mb-2">
            还没有情侣空间
          </h3>
          <p className="text-gray-600">
            创建或加入情侣空间，开始记录你们的故事
          </p>
        </div>
      )}
    </div>
  );

  const renderStorageTab = () => (
    <div className="space-y-6">
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">存储空间使用情况</h3>
        
        {/* 存储进度条 */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-600">已使用空间</span>
            <span className="text-sm font-medium">45.2 MB / 1.0 GB</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-love-pink h-2 rounded-full" style={{ width: '4.5%' }}></div>
          </div>
          <p className="text-xs text-gray-500 mt-1">还剩余 954.8 MB 可用空间</p>
        </div>

        {/* 存储详情 */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-gray-50 rounded-lg p-4 text-center">
            <div className="text-lg font-bold text-gray-800">128</div>
            <div className="text-sm text-gray-600">照片文件</div>
            <div className="text-xs text-gray-500">32.1 MB</div>
          </div>
          <div className="bg-gray-50 rounded-lg p-4 text-center">
            <div className="text-lg font-bold text-gray-800">15</div>
            <div className="text-sm text-gray-600">视频文件</div>
            <div className="text-xs text-gray-500">13.1 MB</div>
          </div>
        </div>

        {/* 文件限制 */}
        <div className="border-t pt-4">
          <h4 className="font-medium text-gray-800 mb-3">当前限制</h4>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">单张照片最大</span>
              <span className="font-medium">10 MB</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">单个视频最大</span>
              <span className="font-medium">100 MB</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">总存储空间</span>
              <span className="font-medium">1 GB</span>
            </div>
          </div>
        </div>

        {/* 升级提示 */}
        <div className="bg-gradient-to-r from-love-pink to-love-purple rounded-lg p-4 text-white mt-6">
          <div className="flex items-center mb-2">
            <Crown className="w-5 h-5 mr-2" />
            <span className="font-semibold">升级VIP获得更多空间</span>
          </div>
          <p className="text-sm text-white/80 mb-3">
            VIP用户可享受10GB存储空间，单文件最大500MB
          </p>
          <button className="bg-white text-love-pink px-4 py-2 rounded-lg font-medium hover:bg-gray-50 transition-colors">
            了解VIP特权
          </button>
        </div>
      </div>
    </div>
  );

  const renderPrivacyTab = () => (
    <div className="space-y-6">
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">隐私与安全</h3>
        
        <div className="space-y-4">
          <div className="flex items-center justify-between py-3 border-b">
            <div>
              <h4 className="font-medium text-gray-800">数据加密</h4>
              <p className="text-sm text-gray-600">所有数据都经过安全加密传输和存储</p>
            </div>
            <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
              <Check className="w-4 h-4 text-white" />
            </div>
          </div>
          
          <div className="flex items-center justify-between py-3 border-b">
            <div>
              <h4 className="font-medium text-gray-800">私密空间</h4>
              <p className="text-sm text-gray-600">只有您和伴侣可以看到空间内的内容</p>
            </div>
            <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
              <Check className="w-4 h-4 text-white" />
            </div>
          </div>
          
          <div className="flex items-center justify-between py-3">
            <div>
              <h4 className="font-medium text-gray-800">定期备份</h4>
              <p className="text-sm text-gray-600">数据定期自动备份，保障数据安全</p>
            </div>
            <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
              <Check className="w-4 h-4 text-white" />
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">数据管理</h3>
        
        <div className="space-y-3">
          <button className="w-full text-left p-3 border border-gray-300 rounded-lg hover:bg-gray-50">
            <h4 className="font-medium text-gray-800">导出数据</h4>
            <p className="text-sm text-gray-600 mt-1">下载您的所有数据副本</p>
          </button>
          
          <button className="w-full text-left p-3 border border-red-300 rounded-lg hover:bg-red-50 text-red-600">
            <h4 className="font-medium">删除账户</h4>
            <p className="text-sm mt-1">永久删除账户和所有相关数据</p>
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div>
        <h1 className="text-2xl font-display font-bold text-gray-800">
          设置
        </h1>
      </div>

      {/* 消息提示 */}
      {message.content && (
        <div className={`rounded-lg p-3 ${
          message.type === 'success' 
            ? 'bg-green-50 border border-green-200 text-green-600' 
            : 'bg-red-50 border border-red-200 text-red-600'
        }`}>
          {message.content}
        </div>
      )}

      {/* 标签导航 */}
      <div className="flex overflow-x-auto space-x-1 bg-gray-100 p-1 rounded-lg">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setActiveTab(id)}
            className={`flex items-center px-4 py-2 rounded-lg font-medium text-sm transition-all whitespace-nowrap ${
              activeTab === id
                ? 'bg-white text-love-pink shadow'
                : 'text-gray-600 hover:text-gray-800'
            }`}
          >
            <Icon className="w-4 h-4 mr-2" />
            {label}
          </button>
        ))}
      </div>

      {/* 标签内容 */}
      <div>
        {activeTab === 'profile' && renderProfileTab()}
        {activeTab === 'couple' && renderCoupleTab()}
        {activeTab === 'storage' && renderStorageTab()}
        {activeTab === 'privacy' && renderPrivacyTab()}
      </div>
    </div>
  );
};

export default SettingsPage;