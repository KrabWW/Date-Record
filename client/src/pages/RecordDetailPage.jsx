import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { recordAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import MediaGallery from '../components/MediaGallery';
import MediaUpload from '../components/MediaUpload';
import { Edit, Trash2, ArrowLeft, MapPin, Calendar, Star, Tag, Camera, Plus } from 'lucide-react';

const RecordDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { couple } = useAuth();
  const [record, setRecord] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    loadRecord();
  }, [id]);

  const loadRecord = async () => {
    try {
      setLoading(true);
      const response = await recordAPI.getById(id);
      setRecord(response.data.record);
    } catch (error) {
      setError('记录加载失败');
      console.error('Failed to load record:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm('确定要删除这条记录吗？此操作无法撤销。')) {
      return;
    }

    try {
      await recordAPI.delete(id);
      navigate('/records');
    } catch (error) {
      alert('删除失败，请稍后重试');
    }
  };

  const renderStars = (rating) => {
    if (!rating) return null;
    return (
      <div className="flex items-center">
        {Array.from({ length: 5 }, (_, i) => (
          <Star
            key={i}
            className={`w-5 h-5 ${
              i < rating ? 'text-yellow-400 fill-current' : 'text-gray-300'
            }`}
          />
        ))}
        <span className="ml-2 text-sm text-gray-600">({rating}/5)</span>
      </div>
    );
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      weekday: 'long'
    });
  };

  const handleUploadSuccess = () => {
    // 媒体上传成功后关闭上传面板
    setShowUpload(false);
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="card animate-pulse">
          <div className="h-6 bg-gray-200 rounded mb-4"></div>
          <div className="h-4 bg-gray-200 rounded mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-3/4"></div>
        </div>
      </div>
    );
  }

  if (error || !record) {
    return (
      <div className="card text-center py-12">
        <p className="text-red-600 mb-4">{error || '记录不存在'}</p>
        <Link to="/records" className="btn-primary">
          返回记录列表
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 头部操作栏 */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/records')}
          className="flex items-center text-gray-600 hover:text-gray-800"
        >
          <ArrowLeft className="w-5 h-5 mr-1" />
          返回
        </button>
        
        <div className="flex space-x-2">
          <Link
            to={`/records/${id}/edit`}
            className="btn-secondary flex items-center"
          >
            <Edit className="w-4 h-4 mr-1" />
            编辑
          </Link>
          <button
            onClick={handleDelete}
            className="btn-danger flex items-center"
          >
            <Trash2 className="w-4 h-4 mr-1" />
            删除
          </button>
        </div>
      </div>

      {/* 记录详情 */}
      <div className="card">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-800 mb-4">
            {record.title}
          </h1>
          
          {/* 基本信息 */}
          <div className="space-y-3">
            <div className="flex items-center text-gray-600">
              <Calendar className="w-5 h-5 mr-3 text-love-pink" />
              <span>{formatDate(record.record_date)}</span>
            </div>
            
            {record.location && (
              <div className="flex items-center text-gray-600">
                <MapPin className="w-5 h-5 mr-3 text-love-pink" />
                <span>{record.location}</span>
              </div>
            )}
            
            {record.rating && (
              <div className="flex items-center">
                <Star className="w-5 h-5 mr-3 text-love-pink" />
                {renderStars(record.rating)}
              </div>
            )}
          </div>
        </div>

        {/* 详细描述 */}
        {record.description && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-3">
              详细描述
            </h3>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-gray-700 whitespace-pre-wrap leading-relaxed">
                {record.description}
              </p>
            </div>
          </div>
        )}

        {/* 标签 */}
        {record.tags && record.tags.length > 0 && (
          <div className="mb-6">
            <div className="flex items-center mb-3">
              <Tag className="w-5 h-5 mr-2 text-love-pink" />
              <h3 className="text-lg font-semibold text-gray-800">标签</h3>
            </div>
            <div className="flex flex-wrap gap-2">
              {record.tags.map((tag, index) => (
                <span key={index} className="tag">
                  {tag}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* 创建信息 */}
        <div className="border-t pt-4 text-sm text-gray-500">
          <p>
            创建时间：{new Date(record.created_at).toLocaleString('zh-CN')}
          </p>
          {record.updated_at !== record.created_at && (
            <p>
              最后修改：{new Date(record.updated_at).toLocaleString('zh-CN')}
            </p>
          )}
        </div>
      </div>

      {/* 媒体内容 */}
      <div className="card">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-gray-800 flex items-center">
            <Camera className="w-5 h-5 mr-2 text-love-pink" />
            照片和视频
          </h3>
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
        </div>

        {/* 上传组件 */}
        {showUpload && (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <div className="flex justify-between items-center mb-3">
              <h4 className="font-medium text-gray-800">上传照片和视频</h4>
              <button
                onClick={() => setShowUpload(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <Plus className="w-4 h-4 transform rotate-45" />
              </button>
            </div>
            <MediaUpload
              recordId={id}
              coupleId={couple?.id}
              onUploadSuccess={handleUploadSuccess}
            />
          </div>
        )}

        {/* 媒体画廊 */}
        <MediaGallery 
          recordId={id}
          coupleId={couple?.id}
        />
      </div>

      {/* 相关操作 */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          相关操作
        </h3>
        <div className="grid grid-cols-2 gap-4">
          <Link
            to="/gallery"
            className="card-interactive text-center"
          >
            <div className="text-2xl mb-2">📸</div>
            <p className="text-sm font-medium">查看全部照片</p>
          </Link>
          <Link
            to="/records/new"
            className="card-interactive text-center"
          >
            <div className="text-2xl mb-2">➕</div>
            <p className="text-sm font-medium">添加记录</p>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default RecordDetailPage;