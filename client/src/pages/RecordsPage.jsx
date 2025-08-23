import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { recordAPI } from '../services/api';
import { Plus, Heart, MapPin, Calendar, Search, List } from 'lucide-react';
import { MoodDisplay } from '../components/MoodSelector';
import { EmotionTagsDisplay } from '../components/EmotionTags';

const RecordsPage = () => {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filter, setFilter] = useState('all'); // all, recent, rated
  
  useEffect(() => {
    loadRecords();
  }, []);

  const loadRecords = async () => {
    try {
      setLoading(true);
      const response = await recordAPI.getAll();
      setRecords(response.data.records || []);
    } catch (error) {
      console.error('Failed to load records:', error);
    } finally {
      setLoading(false);
    }
  };

  // 过滤记录
  const filteredRecords = records.filter(record => {
    // 搜索过滤
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase();
      const matchesSearch = 
        record.title.toLowerCase().includes(searchLower) ||
        (record.location && record.location.toLowerCase().includes(searchLower)) ||
        (record.description && record.description.toLowerCase().includes(searchLower));
      if (!matchesSearch) return false;
    }

    // 类型过滤
    switch (filter) {
      case 'recent':
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return new Date(record.record_date) >= thirtyDaysAgo;
      case 'rated':
        return record.mood && ['amazing', 'happy'].includes(record.mood);
      default:
        return true;
    }
  });

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  // 移除星级评分，使用心情显示替代

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-display font-bold text-gray-800">
            约会记录
          </h1>
        </div>
        
        {/* 加载骨架屏 */}
        <div className="space-y-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="card">
              <div className="animate-pulse">
                <div className="flex items-center">
                  <div className="w-12 h-12 bg-gray-200 rounded-lg mr-3"></div>
                  <div className="flex-1">
                    <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex justify-between items-center">
        <div className="flex items-center space-x-3">
          <h1 className="text-2xl font-display font-bold text-gray-800">
            约会记录
          </h1>
          <Link
            to="/wishlist"
            className="flex items-center text-sm text-love-purple hover:text-love-purple-dark transition-colors"
          >
            <List className="w-4 h-4 mr-1" />
            愿望清单
          </Link>
        </div>
        <Link 
          to="/records/new" 
          className="bg-love-pink text-white p-2 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 transform hover:-translate-y-0.5"
        >
          <Plus className="w-5 h-5" />
        </Link>
      </div>

      {/* 搜索和过滤 */}
      <div className="space-y-4">
        {/* 搜索框 */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="搜索记录..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input-field pl-10"
          />
        </div>

        {/* 过滤标签 */}
        <div className="flex space-x-2 overflow-x-auto">
          {[
            { key: 'all', label: '全部', count: records.length },
            { 
              key: 'recent', 
              label: '最近', 
              count: records.filter(r => {
                const thirtyDaysAgo = new Date();
                thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
                return new Date(r.record_date) >= thirtyDaysAgo;
              }).length 
            },
            { 
              key: 'rated', 
              label: '开心', 
              count: records.filter(r => r.mood && ['amazing', 'happy'].includes(r.mood)).length 
            }
          ].map(({ key, label, count }) => (
            <button
              key={key}
              onClick={() => setFilter(key)}
              className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
                filter === key
                  ? 'bg-love-pink text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {label} ({count})
            </button>
          ))}
        </div>
      </div>

      {/* 记录列表 */}
      <div className="space-y-4">
        {filteredRecords.length > 0 ? (
          filteredRecords.map((record) => (
            <Link
              key={record.id}
              to={`/records/${record.id}`}
              className="card-interactive"
            >
              <div className="flex items-start">
                {/* 左侧图标 */}
                <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-love-pink to-love-purple rounded-lg flex items-center justify-center mr-4">
                  <Heart className="w-6 h-6 text-white" />
                </div>

                {/* 主要内容 */}
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="font-semibold text-gray-800 text-truncate">
                      {record.title}
                    </h3>
                    <div className="flex-shrink-0 ml-2">
                      {record.mood && (
                        <MoodDisplay 
                          mood={record.mood} 
                          showLabel={false} 
                          size="small" 
                        />
                      )}
                    </div>
                  </div>

                  {/* 详细信息 */}
                  <div className="flex items-center text-sm text-gray-600 mb-2">
                    <Calendar className="w-4 h-4 mr-1" />
                    <span>{formatDate(record.record_date)}</span>
                    
                    {record.location && (
                      <>
                        <span className="mx-2">·</span>
                        <MapPin className="w-4 h-4 mr-1" />
                        <span className="text-truncate">{record.location}</span>
                      </>
                    )}
                  </div>

                  {/* 描述 */}
                  {record.description && (
                    <p className="text-sm text-gray-600 text-truncate-2 mb-2">
                      {record.description}
                    </p>
                  )}

                  {/* 情感标签 */}
                  {record.emotion_tags && record.emotion_tags.length > 0 && (
                    <div className="mb-2">
                      <EmotionTagsDisplay 
                        tags={record.emotion_tags} 
                        size="small"
                        maxDisplay={3}
                      />
                    </div>
                  )}

                  {/* 标签 */}
                  {record.tags && record.tags.length > 0 && (
                    <div className="flex flex-wrap gap-1">
                      {record.tags.slice(0, 3).map((tag, index) => (
                        <span key={index} className="tag text-xs">
                          {tag}
                        </span>
                      ))}
                      {record.tags.length > 3 && (
                        <span className="text-xs text-gray-400">
                          +{record.tags.length - 3}
                        </span>
                      )}
                    </div>
                  )}
                </div>

                {/* 右侧指示器 */}
                <div className="flex-shrink-0 ml-2">
                  <div className="w-2 h-2 bg-love-pink rounded-full"></div>
                </div>
              </div>
            </Link>
          ))
        ) : (
          <div className="card text-center py-12">
            <Heart className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-800 mb-2">
              {searchTerm || filter !== 'all' ? '没有找到匹配的记录' : '还没有约会记录'}
            </h3>
            <p className="text-gray-600 mb-6">
              {searchTerm || filter !== 'all' 
                ? '试试调整搜索条件或过滤选项'
                : '添加你们的第一个约会记录，开始记录美好时光'
              }
            </p>
            {(!searchTerm && filter === 'all') && (
              <Link to="/records/new" className="btn-primary">
                添加记录
              </Link>
            )}
          </div>
        )}
      </div>

      {/* 底部统计 */}
      {records.length > 0 && (
        <div className="card bg-gray-50">
          <div className="text-center">
            <p className="text-sm text-gray-600">
              共有 <span className="font-semibold text-love-pink">{records.length}</span> 个约会记录
              {filteredRecords.length !== records.length && (
                <>, 显示 <span className="font-semibold">{filteredRecords.length}</span> 个</>
              )}
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default RecordsPage;