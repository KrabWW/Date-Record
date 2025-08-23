import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { recordAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import MediaUpload from '../components/MediaUpload';
import MediaGallery from '../components/MediaGallery';
import MoodSelector from '../components/MoodSelector';
import EmotionTags from '../components/EmotionTags';
import { ArrowLeft, Save, MapPin, Calendar, Tag, Camera, Plus, Heart } from 'lucide-react';

const RecordEditPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { couple } = useAuth();
  const isNew = !id || id === 'new';
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    record_date: '',
    location: '',
    mood: 'good',
    emotion_tags: [],
    tags: []
  });
  const [tagInput, setTagInput] = useState('');
  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    if (!isNew) {
      loadRecord();
    } else {
      // 新建记录时设置默认日期为今天
      setFormData(prev => ({
        ...prev,
        record_date: new Date().toISOString().split('T')[0]
      }));
    }
  }, [id, isNew]);

  const loadRecord = async () => {
    try {
      setLoading(true);
      const response = await recordAPI.getById(id);
      const record = response.data.record;
      setFormData({
        title: record.title,
        description: record.description || '',
        record_date: record.record_date,
        location: record.location || '',
        mood: record.mood || 'good',
        emotion_tags: record.emotion_tags || [],
        tags: record.tags || []
      });
    } catch (error) {
      setError('记录加载失败');
      console.error('Failed to load record:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleMoodChange = (mood) => {
    setFormData(prev => ({
      ...prev,
      mood
    }));
  };

  const handleEmotionTagsChange = (emotion_tags) => {
    setFormData(prev => ({
      ...prev,
      emotion_tags
    }));
  };

  const handleAddTag = (e) => {
    e.preventDefault();
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, tagInput.trim()]
      }));
      setTagInput('');
    }
  };

  const handleRemoveTag = (tagToRemove) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToRemove)
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim()) {
      setError('请输入记录标题');
      return;
    }

    setSaving(true);
    setError('');

    try {
      const submitData = {
        ...formData,
        tags: formData.tags.length > 0 ? formData.tags : undefined
      };

      if (isNew) {
        const response = await recordAPI.create(submitData);
        navigate(`/records/${response.data.record.id}`);
      } else {
        await recordAPI.update(id, submitData);
        navigate(`/records/${id}`);
      }
    } catch (error) {
      setError(isNew ? '创建失败，请稍后重试' : '更新失败，请稍后重试');
      console.error('Failed to save record:', error);
    } finally {
      setSaving(false);
    }
  };

  // 移除星级评分组件，使用心情选择器替代

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

  return (
    <div className="space-y-6">
      {/* 头部 */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate(isNew ? '/records' : `/records/${id}`)}
          className="flex items-center text-gray-600 hover:text-gray-800"
        >
          <ArrowLeft className="w-5 h-5 mr-1" />
          返回
        </button>
        
        <h1 className="text-xl font-bold text-gray-800">
          {isNew ? '添加记录' : '编辑记录'}
        </h1>
      </div>

      {/* 错误信息 */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3">
          <p className="text-red-600 text-sm">{error}</p>
        </div>
      )}

      {/* 编辑表单 */}
      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="card space-y-6">
          {/* 标题 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              记录标题 *
            </label>
            <input
              type="text"
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              className="input-field"
              placeholder="给这次约会起个标题吧..."
              required
            />
          </div>

          {/* 日期 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Calendar className="w-4 h-4 inline mr-1" />
              约会日期 *
            </label>
            <input
              type="date"
              name="record_date"
              value={formData.record_date}
              onChange={handleInputChange}
              className="input-field"
              required
            />
          </div>

          {/* 地点 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <MapPin className="w-4 h-4 inline mr-1" />
              地点
            </label>
            <input
              type="text"
              name="location"
              value={formData.location}
              onChange={handleInputChange}
              className="input-field"
              placeholder="在哪里度过了美好时光？"
            />
          </div>

          {/* 心情选择 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              <Heart className="w-4 h-4 inline mr-1" />
              今天的心情如何？
            </label>
            <MoodSelector
              selectedMood={formData.mood}
              onMoodChange={handleMoodChange}
              size="large"
              showLabels={true}
            />
          </div>

          {/* 情感标签 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              <Tag className="w-4 h-4 inline mr-1" />
              这次约会的感觉
            </label>
            <EmotionTags
              selectedTags={formData.emotion_tags}
              onTagsChange={handleEmotionTagsChange}
              maxTags={3}
            />
          </div>

          {/* 标签 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Tag className="w-4 h-4 inline mr-1" />
              标签
            </label>
            
            {/* 标签列表 */}
            {formData.tags.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-3">
                {formData.tags.map((tag, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-love-pink text-white"
                  >
                    {tag}
                    <button
                      type="button"
                      onClick={() => handleRemoveTag(tag)}
                      className="ml-2 hover:text-gray-200"
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            )}
            
            {/* 添加标签 */}
            <div className="flex">
              <input
                type="text"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                className="input-field flex-1"
                placeholder="添加标签，如：浪漫、海边、生日..."
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    handleAddTag(e);
                  }
                }}
              />
              <button
                type="button"
                onClick={handleAddTag}
                className="ml-2 btn-secondary"
                disabled={!tagInput.trim()}
              >
                添加
              </button>
            </div>
          </div>

          {/* 详细描述 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              详细描述
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              rows={6}
              className="input-field"
              placeholder="记录这次约会的美好细节..."
            />
            <p className="text-xs text-gray-500 mt-1">
              可以记录约会的具体过程、感受、有趣的事情等
            </p>
          </div>
        </div>

        {/* 媒体内容（仅编辑模式显示） */}
        {!isNew && (
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
        )}

        {/* 提交按钮 */}
        <div className="flex space-x-4">
          <button
            type="submit"
            disabled={saving}
            className="flex-1 btn-primary disabled:opacity-50"
          >
            <Save className="w-4 h-4 mr-1" />
            {saving ? '保存中...' : (isNew ? '创建记录' : '更新记录')}
          </button>
          
          <button
            type="button"
            onClick={() => navigate(isNew ? '/records' : `/records/${id}`)}
            className="btn-secondary"
            disabled={saving}
          >
            取消
          </button>
        </div>
      </form>
    </div>
  );
};

export default RecordEditPage;