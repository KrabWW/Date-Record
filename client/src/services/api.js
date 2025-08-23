import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

// 创建axios实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 请求拦截器 - 自动添加token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器 - 统一处理响应和错误
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    // token过期或无效，清除本地存储并跳转登录
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/auth';
    }
    
    // 网络错误处理
    if (!error.response) {
      console.error('Network Error:', error.message);
      return Promise.reject({
        error: '网络连接错误',
        message: '请检查网络连接后重试'
      });
    }
    
    // 返回统一的错误格式
    return Promise.reject(error.response.data || error.response);
  }
);

// 认证相关API
export const authAPI = {
  // 用户注册
  register: (userData) => api.post('/auth/register', userData),
  
  // 用户登录
  login: (credentials) => api.post('/auth/login', credentials),
  
  // 获取当前用户信息
  getMe: () => api.get('/auth/me'),
  
  // 更新用户资料
  updateProfile: (data) => api.put('/auth/profile', data),
  
  // 登出
  logout: () => api.post('/auth/logout')
};

// 情侣空间相关API
export const coupleAPI = {
  // 创建情侣空间
  create: (data) => api.post('/couples', data),
  
  // 通过邀请码加入
  join: (inviteCode) => api.post('/couples/join', { invite_code: inviteCode }),
  
  // 获取当前情侣空间
  getCurrent: () => api.get('/couples/me'),
  
  // 更新情侣空间信息
  update: (data) => api.put('/couples/me', data),
  
  // 解除情侣关系
  delete: () => api.delete('/couples/me')
};

// 约会记录相关API
export const recordAPI = {
  // 获取记录列表
  getAll: (params = {}) => api.get('/records', { params }),
  
  // 获取单个记录详情
  getById: (id) => api.get(`/records/${id}`),
  
  // 创建记录
  create: (data) => api.post('/records', data),
  
  // 更新记录
  update: (id, data) => api.put(`/records/${id}`, data),
  
  // 删除记录
  delete: (id) => api.delete(`/records/${id}`),
  
  // 获取统计信息
  getStats: () => api.get('/records/stats/summary')
};

// 愿望清单相关API
export const wishlistAPI = {
  // 获取愿望列表
  getAll: (params = {}) => api.get('/wishlists', { params }),
  
  // 获取单个愿望详情
  getById: (id) => api.get(`/wishlists/${id}`),
  
  // 创建愿望
  create: (data) => api.post('/wishlists', data),
  
  // 更新愿望
  update: (id, data) => api.put(`/wishlists/${id}`, data),
  
  // 标记完成/未完成
  toggleComplete: (id, isCompleted) => 
    api.patch(`/wishlists/${id}/complete`, { is_completed: isCompleted }),
  
  // 转换为约会记录
  convertToRecord: (id, data) => 
    api.post(`/wishlists/${id}/convert-to-record`, data),
  
  // 删除愿望
  delete: (id) => api.delete(`/wishlists/${id}`),
  
  // 批量操作
  batchAction: (action, wishlistIds) => 
    api.post('/wishlists/batch', { action, wishlist_ids: wishlistIds })
};

// 媒体上传相关API
export const mediaAPI = {
  // 上传照片
  uploadPhoto: (formData) => 
    api.post('/upload/photo', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  
  // 上传视频
  uploadVideo: (formData) => 
    api.post('/upload/video', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  
  // 获取媒体文件列表
  getMedia: (recordId = null) => {
    const endpoint = recordId ? `/upload/media/${recordId}` : '/upload/media';
    return api.get(endpoint);
  },
  
  // 删除媒体文件
  deleteMedia: (mediaId) => api.delete(`/upload/media/${mediaId}`),
  
  // 获取存储空间信息
  getStorageInfo: () => api.get('/upload/storage-info')
};

// 向后兼容的别名
export const uploadAPI = mediaAPI;

// 工具函数
export const utils = {
  // 构建完整的图片URL
  getImageUrl: (photoUrl) => {
    if (!photoUrl) return null;
    if (photoUrl.startsWith('http')) return photoUrl;
    
    // 在开发环境下，直接使用相对路径，利用Vite的代理配置
    // 在生产环境下，使用配置的服务器URL
    if (import.meta.env.DEV) {
      // 确保photoUrl以/开头，开发环境使用代理
      return photoUrl.startsWith('/') ? photoUrl : `/${photoUrl}`;
    } else {
      // 生产环境下使用环境变量中的服务器URL
      const serverUrl = import.meta.env.VITE_SERVER_URL || window.location.origin;
      const cleanPhotoUrl = photoUrl.startsWith('/') ? photoUrl : `/${photoUrl}`;
      return `${serverUrl}${cleanPhotoUrl}`;
    }
  },
  
  // 格式化日期
  formatDate: (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  },
  
  // 格式化相对时间
  formatRelativeTime: (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    const now = new Date();
    const diffInMs = now - date;
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));
    
    if (diffInDays === 0) return '今天';
    if (diffInDays === 1) return '昨天';
    if (diffInDays < 30) return `${diffInDays}天前`;
    if (diffInDays < 365) return `${Math.floor(diffInDays / 30)}个月前`;
    return `${Math.floor(diffInDays / 365)}年前`;
  }
};

export default api;