import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { recordAPI, wishlistAPI } from '../services/api';
import { Plus, Heart, List, Camera, TrendingUp, Users, X } from 'lucide-react';
import { MoodDisplay } from '../components/MoodSelector';

const HomePage = () => {
  const { couple, getPartner, hasCouple } = useAuth();
  const [stats, setStats] = useState({
    totalRecords: 0,
    completedWishlists: 0,
    totalPhotos: 0,
    recentRecords: 0
  });
  const [recentRecords, setRecentRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showCouplePrompt, setShowCouplePrompt] = useState(!hasCouple);

  const partner = getPartner();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 并行加载统计数据
      const [statsResponse, recordsResponse, wishlistResponse] = await Promise.all([
        recordAPI.getStats().catch(() => ({ data: {} })),
        recordAPI.getAll({ limit: 3 }).catch(() => ({ data: { records: [] } })),
        wishlistAPI.getAll({ completed: 'true', limit: 5 }).catch(() => ({ data: { stats: {} } }))
      ]);

      // 设置统计数据
      if (statsResponse.data) {
        setStats({
          totalRecords: statsResponse.data.total_records || 0,
          recentRecords: statsResponse.data.recent_records || 0,
          totalPhotos: 0, // 暂时设为0，后续可以添加照片统计
          completedWishlists: wishlistResponse.data.stats?.completed || 0
        });
      }

      // 设置最近记录
      if (recordsResponse.data?.records) {
        setRecentRecords(recordsResponse.data.records);
      }
    } catch (error) {
      console.error('Failed to load home data:', error);
      setError('数据加载失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  // 计算在一起天数
  const getDaysTogether = () => {
    if (!couple?.anniversary_date) return 0;
    const anniversaryDate = new Date(couple.anniversary_date);
    const today = new Date();
    const diffTime = Math.abs(today - anniversaryDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  // 快速操作按钮
  const quickActions = [
    {
      title: '添加记录',
      icon: Plus,
      link: '/records',
      color: 'bg-love-pink',
      description: '记录美好时光'
    },
    {
      title: '愿望清单',
      icon: List,
      link: '/wishlist',
      color: 'bg-love-purple',
      description: '规划未来约会'
    },
    {
      title: '相册',
      icon: Camera,
      link: '/gallery',
      color: 'bg-gradient-to-br from-love-pink to-love-purple',
      description: '浏览回忆'
    }
  ];

  if (loading) {
    return (
      <div className="animate-fade-in">
        {/* 加载骨架屏 */}
        <div className="space-y-6">
          <div className="card">
            <div className="animate-pulse">
              <div className="h-8 bg-gray-200 rounded w-3/4 mb-4"></div>
              <div className="h-4 bg-gray-200 rounded w-1/2"></div>
            </div>
          </div>
          
          <div className="grid grid-cols-3 gap-4">
            {[1, 2, 3].map(i => (
              <div key={i} className="card">
                <div className="animate-pulse">
                  <div className="w-12 h-12 bg-gray-200 rounded-full mb-3"></div>
                  <div className="h-4 bg-gray-200 rounded"></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // 错误状态显示
  if (error) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="card text-center py-12">
          <div className="text-red-500 mb-4">
            <Heart className="w-16 h-16 mx-auto opacity-50" />
          </div>
          <h3 className="text-lg font-medium text-gray-800 mb-2">出现错误</h3>
          <p className="text-gray-600 mb-6">{error}</p>
          <button 
            onClick={loadData}
            className="btn-primary"
          >
            重新加载
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* 欢迎横幅 */}
      <div className="card gradient-bg text-white">
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <h2 className="text-xl font-display font-bold mb-1">
              {couple?.couple_name || 'Love4Lili'}
            </h2>
            <p className="text-white/80 text-sm">
              {partner?.name ? (
                <>与 {partner.name} 在一起</>
              ) : (
                '等待伴侣加入...'
              )}
            </p>
            {couple?.anniversary_date && (
              <div className="flex items-center mt-2 text-sm">
                <Heart className="w-4 h-4 mr-1" />
                <span>第 {getDaysTogether()} 天</span>
              </div>
            )}
          </div>
          
          <div className="text-right">
            <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center">
              <Heart className="w-8 h-8 animate-heartbeat" />
            </div>
          </div>
        </div>
      </div>

      {/* 可选的情侣空间设置提示 */}
      {showCouplePrompt && !hasCouple && (
        <div className="card border-2 border-dashed border-love-pink bg-love-pink/5">
          <div className="flex items-start">
            <div className="flex-shrink-0 w-10 h-10 bg-love-pink/20 rounded-lg flex items-center justify-center mr-3">
              <Users className="w-5 h-5 text-love-pink" />
            </div>
            <div className="flex-1">
              <h4 className="font-medium text-gray-800 mb-1">创建情侣空间</h4>
              <p className="text-sm text-gray-600 mb-3">
                邀请您的伴侣一起使用，共同记录美好时光。当然，您也可以先单独使用。
              </p>
              <div className="flex space-x-2">
                <Link
                  to="/couple-setup"
                  className="btn-primary text-sm"
                >
                  立即设置
                </Link>
                <button
                  onClick={() => setShowCouplePrompt(false)}
                  className="btn-secondary text-sm"
                >
                  稍后再说
                </button>
              </div>
            </div>
            <button
              onClick={() => setShowCouplePrompt(false)}
              className="flex-shrink-0 text-gray-400 hover:text-gray-600 ml-2"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* 核心数据指标（最多3个） */}
      <div className="grid grid-cols-2 gap-4">
        <div className="card text-center">
          <div className="text-3xl font-bold text-love-pink mb-1">
            {stats.totalRecords}
          </div>
          <div className="text-sm text-gray-600">约会记录</div>
        </div>
        
        <div className="card text-center">
          <div className="text-3xl font-bold text-love-purple mb-1">
            {stats.completedWishlists}
          </div>
          <div className="text-sm text-gray-600">完成愿望</div>
        </div>
      </div>

      {/* 主要操作区域（突出核心功能） */}
      <div className="card">
        <div className="grid grid-cols-2 gap-4">
          <Link
            to="/records"
            className="bg-gradient-to-br from-love-pink to-love-purple text-white p-6 rounded-xl text-center hover:shadow-lg transition-all duration-200 transform hover:-translate-y-1"
          >
            <Heart className="w-8 h-8 mx-auto mb-2" />
            <h3 className="font-semibold text-lg mb-1">记录约会</h3>
            <p className="text-sm opacity-90">记录美好时光</p>
          </Link>
          
          <Link
            to="/gallery"
            className="bg-gradient-to-br from-love-purple to-love-pink text-white p-6 rounded-xl text-center hover:shadow-lg transition-all duration-200 transform hover:-translate-y-1"
          >
            <Camera className="w-8 h-8 mx-auto mb-2" />
            <h3 className="font-semibold text-lg mb-1">相册</h3>
            <p className="text-sm opacity-90">浏览回忆</p>
          </Link>
        </div>
      </div>

      {/* 最近记录 */}
      {recentRecords.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-800">最近记录</h3>
            <Link to="/records" className="text-love-pink text-sm font-medium">
              查看全部
            </Link>
          </div>
          
          <div className="space-y-3">
            {recentRecords.map((record) => (
              <Link
                key={record.id}
                to={`/records/${record.id}`}
                className="card-interactive"
              >
                <div className="flex items-center">
                  <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-love-pink to-love-purple rounded-lg flex items-center justify-center mr-3">
                    <Heart className="w-6 h-6 text-white" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <h4 className="font-medium text-gray-800 text-truncate">
                      {record.title}
                    </h4>
                    <div className="flex items-center text-sm text-gray-600 mt-1">
                      <span>{new Date(record.record_date).toLocaleDateString('zh-CN')}</span>
                      {record.location && (
                        <>
                          <span className="mx-2">·</span>
                          <span className="text-truncate">{record.location}</span>
                        </>
                      )}
                    </div>
                  </div>
                  
                  {record.mood && (
                    <div className="flex-shrink-0">
                      <MoodDisplay 
                        mood={record.mood} 
                        showLabel={false} 
                        size="small" 
                      />
                    </div>
                  )}
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* 本月统计 */}
      {stats.recentRecords > 0 && (
        <div className="card">
          <div className="flex items-center">
            <div className="flex-shrink-0 w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center mr-3">
              <TrendingUp className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <h4 className="font-medium text-gray-800">本月表现</h4>
              <p className="text-sm text-gray-600">
                本月共记录了 {stats.recentRecords} 次约会，继续保持哦！
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 空状态提示 */}
      {stats.totalRecords === 0 && (
        <div className="card text-center py-12">
          <Heart className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-800 mb-2">
            开始记录你们的故事
          </h3>
          <p className="text-gray-600 mb-6">
            添加第一个约会记录，开启美好回忆之旅
          </p>
          <Link to="/records" className="btn-primary">
            添加第一个记录
          </Link>
        </div>
      )}
    </div>
  );
};

export default HomePage;