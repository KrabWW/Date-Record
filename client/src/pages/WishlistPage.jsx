import React, { useState, useEffect } from 'react';
import { wishlistAPI } from '../services/api';
import { Plus, Calendar, Target, Check, Edit, Trash2, Filter } from 'lucide-react';

const WishlistPage = () => {
  const [wishlists, setWishlists] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // all, pending, completed
  const [showForm, setShowForm] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 3,
    target_date: ''
  });

  useEffect(() => {
    loadWishlists();
  }, []);

  const loadWishlists = async () => {
    try {
      setLoading(true);
      const response = await wishlistAPI.getAll();
      setWishlists(response.data.wishlists || []);
    } catch (error) {
      console.error('Failed to load wishlists:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim()) return;

    try {
      if (editingItem) {
        await wishlistAPI.update(editingItem.id, formData);
      } else {
        await wishlistAPI.create(formData);
      }
      
      resetForm();
      loadWishlists();
    } catch (error) {
      console.error('Failed to save wishlist:', error);
      alert('保存失败，请稍后重试');
    }
  };

  const handleEdit = (item) => {
    setEditingItem(item);
    setFormData({
      title: item.title,
      description: item.description || '',
      priority: item.priority,
      target_date: item.target_date || ''
    });
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('确定要删除这个愿望吗？')) return;
    
    try {
      await wishlistAPI.delete(id);
      loadWishlists();
    } catch (error) {
      console.error('Failed to delete wishlist:', error);
      alert('删除失败，请稍后重试');
    }
  };

  const handleToggleComplete = async (item) => {
    try {
      if (!item.is_completed) {
        await wishlistAPI.markComplete(item.id);
      } else {
        // 如果已完成，则取消完成状态
        await wishlistAPI.update(item.id, { is_completed: false });
      }
      loadWishlists();
    } catch (error) {
      console.error('Failed to toggle completion:', error);
      alert('操作失败，请稍后重试');
    }
  };

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      priority: 3,
      target_date: ''
    });
    setEditingItem(null);
    setShowForm(false);
  };

  const filteredWishlists = wishlists.filter(item => {
    switch (filter) {
      case 'pending':
        return !item.is_completed;
      case 'completed':
        return item.is_completed;
      default:
        return true;
    }
  });

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 5: return 'text-red-600 bg-red-100';
      case 4: return 'text-orange-600 bg-orange-100';
      case 3: return 'text-blue-600 bg-blue-100';
      case 2: return 'text-green-600 bg-green-100';
      case 1: return 'text-gray-600 bg-gray-100';
      default: return 'text-blue-600 bg-blue-100';
    }
  };

  const getPriorityText = (priority) => {
    const texts = { 5: '最高', 4: '高', 3: '中', 2: '低', 1: '最低' };
    return texts[priority] || '中';
  };

  const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    const now = new Date();
    const isOverdue = date < now && !dateString.includes('completed');
    
    return {
      text: date.toLocaleDateString('zh-CN'),
      isOverdue
    };
  };

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-display font-bold text-gray-800">
            愿望清单
          </h1>
        </div>
        
        {[1, 2, 3].map(i => (
          <div key={i} className="card animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div className="h-3 bg-gray-200 rounded w-1/2"></div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 页面标题 */}
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-display font-bold text-gray-800">
          愿望清单
        </h1>
        <button
          onClick={() => setShowForm(true)}
          className="bg-love-purple text-white p-2 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 transform hover:-translate-y-0.5"
        >
          <Plus className="w-5 h-5" />
        </button>
      </div>

      {/* 过滤标签 */}
      <div className="flex space-x-2 overflow-x-auto">
        {[
          { key: 'all', label: '全部', count: wishlists.length },
          { 
            key: 'pending', 
            label: '待完成', 
            count: wishlists.filter(w => !w.is_completed).length 
          },
          { 
            key: 'completed', 
            label: '已完成', 
            count: wishlists.filter(w => w.is_completed).length 
          }
        ].map(({ key, label, count }) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
              filter === key
                ? 'bg-love-purple text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {label} ({count})
          </button>
        ))}
      </div>

      {/* 愿望清单 */}
      <div className="space-y-4">
        {filteredWishlists.length > 0 ? (
          filteredWishlists.map((item) => {
            const targetDate = formatDate(item.target_date);
            return (
              <div
                key={item.id}
                className={`card ${item.is_completed ? 'bg-green-50 border-green-200' : ''}`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1 min-w-0">
                    {/* 标题和完成状态 */}
                    <div className="flex items-start mb-2">
                      <button
                        onClick={() => handleToggleComplete(item)}
                        className={`flex-shrink-0 w-5 h-5 rounded-full border-2 mr-3 mt-0.5 transition-colors ${
                          item.is_completed
                            ? 'bg-green-500 border-green-500 text-white'
                            : 'border-gray-300 hover:border-love-purple'
                        }`}
                      >
                        {item.is_completed && <Check className="w-3 h-3" />}
                      </button>
                      
                      <h3 className={`font-semibold ${
                        item.is_completed 
                          ? 'text-gray-500 line-through' 
                          : 'text-gray-800'
                      }`}>
                        {item.title}
                      </h3>
                    </div>

                    {/* 描述 */}
                    {item.description && (
                      <p className={`text-sm mb-3 ml-8 ${
                        item.is_completed ? 'text-gray-400' : 'text-gray-600'
                      }`}>
                        {item.description}
                      </p>
                    )}

                    {/* 元信息 */}
                    <div className="flex items-center text-sm text-gray-500 ml-8 space-x-4">
                      {/* 优先级 */}
                      <span className={`px-2 py-1 rounded text-xs font-medium ${getPriorityColor(item.priority)}`}>
                        <Target className="w-3 h-3 inline mr-1" />
                        {getPriorityText(item.priority)}优先级
                      </span>

                      {/* 目标日期 */}
                      {item.target_date && (
                        <span className={`flex items-center ${
                          targetDate.isOverdue && !item.is_completed 
                            ? 'text-red-600' 
                            : 'text-gray-500'
                        }`}>
                          <Calendar className="w-3 h-3 mr-1" />
                          {targetDate.text}
                          {targetDate.isOverdue && !item.is_completed && (
                            <span className="ml-1 text-red-600">（已过期）</span>
                          )}
                        </span>
                      )}

                      {/* 完成日期 */}
                      {item.completed_date && (
                        <span className="text-green-600">
                          <Check className="w-3 h-3 inline mr-1" />
                          {new Date(item.completed_date).toLocaleDateString('zh-CN')}完成
                        </span>
                      )}
                    </div>
                  </div>

                  {/* 操作按钮 */}
                  <div className="flex space-x-2 ml-4">
                    <button
                      onClick={() => handleEdit(item)}
                      className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100"
                    >
                      <Edit className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(item.id)}
                      className="p-2 text-gray-500 hover:text-red-600 rounded-lg hover:bg-gray-100"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        ) : (
          <div className="card text-center py-12">
            <Target className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-800 mb-2">
              {filter === 'completed' 
                ? '还没有完成任何愿望' 
                : filter === 'pending'
                  ? '没有待完成的愿望'
                  : '还没有添加愿望'
              }
            </h3>
            <p className="text-gray-600 mb-6">
              {filter === 'all' 
                ? '添加你们想要一起做的事情，开始规划美好未来'
                : '尝试调整过滤选项查看其他愿望'
              }
            </p>
            {filter === 'all' && (
              <button
                onClick={() => setShowForm(true)}
                className="btn-primary"
              >
                添加第一个愿望
              </button>
            )}
          </div>
        )}
      </div>

      {/* 添加/编辑表单模态框 */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full max-h-screen overflow-y-auto">
            <div className="p-6">
              <h2 className="text-xl font-bold text-gray-800 mb-4">
                {editingItem ? '编辑愿望' : '添加新愿望'}
              </h2>
              
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    愿望标题 *
                  </label>
                  <input
                    type="text"
                    value={formData.title}
                    onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                    className="input-field"
                    placeholder="想要一起做的事情..."
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    详细描述
                  </label>
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                    className="input-field"
                    rows={3}
                    placeholder="具体说明这个愿望..."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    优先级
                  </label>
                  <select
                    value={formData.priority}
                    onChange={(e) => setFormData(prev => ({ ...prev, priority: parseInt(e.target.value) }))}
                    className="input-field"
                  >
                    <option value={5}>最高优先级</option>
                    <option value={4}>高优先级</option>
                    <option value={3}>中优先级</option>
                    <option value={2}>低优先级</option>
                    <option value={1}>最低优先级</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    目标日期（可选）
                  </label>
                  <input
                    type="date"
                    value={formData.target_date}
                    onChange={(e) => setFormData(prev => ({ ...prev, target_date: e.target.value }))}
                    className="input-field"
                    min={new Date().toISOString().split('T')[0]}
                  />
                </div>

                <div className="flex space-x-4 pt-4">
                  <button
                    type="submit"
                    className="flex-1 btn-primary"
                  >
                    {editingItem ? '更新' : '添加'}
                  </button>
                  <button
                    type="button"
                    onClick={resetForm}
                    className="btn-secondary"
                  >
                    取消
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default WishlistPage;