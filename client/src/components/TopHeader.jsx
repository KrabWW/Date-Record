import React from 'react';
import { useAuth } from '../context/AuthContext';
import { utils } from '../services/api';

const TopHeader = () => {
  const { couple, getPartner } = useAuth();
  const partner = getPartner();
  
  // 计算在一起的天数
  const getDaysTogether = () => {
    if (!couple?.anniversary_date) return 0;
    const anniversaryDate = new Date(couple.anniversary_date);
    const today = new Date();
    const diffTime = Math.abs(today - anniversaryDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  return (
    <header className="navbar px-4 py-3">
      <div className="flex items-center justify-between max-w-lg mx-auto w-full">
        {/* 左侧：情侣信息 */}
        <div className="flex items-center space-x-3">
          <div className="flex -space-x-2">
            {/* 用户头像 */}
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-love-pink to-love-purple flex items-center justify-center text-white font-medium text-sm">
              {couple?.user1_name?.charAt(0) || 'A'}
            </div>
            {/* 伴侣头像 */}
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-love-purple to-love-pink flex items-center justify-center text-white font-medium text-sm border-2 border-white">
              {partner?.name?.charAt(0) || '?'}
            </div>
          </div>
          
          <div>
            <h1 className="font-display font-semibold text-lg text-gray-800">
              {couple?.couple_name || 'Love4Lili'}
            </h1>
            {couple?.anniversary_date && (
              <p className="text-sm text-gray-600">
                在一起 {getDaysTogether()} 天 💕
              </p>
            )}
          </div>
        </div>

        {/* 右侧：爱心图标 */}
        <div className="text-love-pink">
          <svg className="w-8 h-8 animate-heartbeat" fill="currentColor" viewBox="0 0 64 64">
            <path d="M32 54C32 54 8 42 8 24C8 18.4772 12.4772 14 18 14C22.4183 14 26.1829 16.5357 28 20.1433C29.8171 16.5357 33.5817 14 38 14C43.5228 14 48 18.4772 48 24C48 42 32 54 32 54Z" />
          </svg>
        </div>
      </div>
    </header>
  );
};

export default TopHeader;