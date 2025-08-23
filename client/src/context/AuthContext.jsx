import React, { createContext, useContext, useState, useEffect } from 'react';
import { authAPI, coupleAPI } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth必须在AuthProvider内使用');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [couple, setCouple] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // 初始化认证状态
  useEffect(() => {
    const initAuth = async () => {
      try {
        const token = localStorage.getItem('token');
        const storedUser = localStorage.getItem('user');
        
        if (token && storedUser) {
          // 从本地存储恢复用户信息
          setUser(JSON.parse(storedUser));
          
          // 验证token是否仍然有效
          try {
            const response = await authAPI.getMe();
            setUser(response.data.user);
            
            // 获取情侣空间信息
            await loadCoupleInfo();
          } catch (error) {
            // token无效，清除本地存储
            clearAuth();
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        clearAuth();
      } finally {
        setLoading(false);
      }
    };

    initAuth();
  }, []);

  // 加载情侣空间信息
  const loadCoupleInfo = async () => {
    try {
      const response = await coupleAPI.getCurrent();
      setCouple(response.data.couple);
    } catch (error) {
      // 没有情侣空间也是正常情况
      if (error.status !== 404) {
        console.error('Failed to load couple info:', error);
      }
    }
  };

  // 清除认证信息
  const clearAuth = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
    setCouple(null);
    setError(null);
  };

  // 用户注册
  const register = async (userData) => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await authAPI.register(userData);
      const { token, user } = response.data;
      
      // 保存到本地存储
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      
      setUser(user);
      
      return { success: true, user };
    } catch (error) {
      const errorMessage = error.message || '注册失败，请稍后重试';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 用户登录
  const login = async (credentials) => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await authAPI.login(credentials);
      const { token, user } = response.data;
      
      // 保存到本地存储
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      
      setUser(user);
      
      // 加载情侣空间信息
      await loadCoupleInfo();
      
      return { success: true, user };
    } catch (error) {
      const errorMessage = error.message || '登录失败，请检查邮箱和密码';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 用户登出
  const logout = async () => {
    try {
      await authAPI.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      clearAuth();
    }
  };

  // 更新用户资料
  const updateProfile = async (data) => {
    try {
      setLoading(true);
      const response = await authAPI.updateProfile(data);
      const updatedUser = response.data.user;
      
      localStorage.setItem('user', JSON.stringify(updatedUser));
      setUser(updatedUser);
      
      return { success: true, user: updatedUser };
    } catch (error) {
      const errorMessage = error.message || '更新失败，请稍后重试';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 创建情侣空间
  const createCouple = async (data) => {
    try {
      setLoading(true);
      const response = await coupleAPI.create(data);
      const newCouple = response.data.couple;
      
      setCouple(newCouple);
      return { success: true, couple: newCouple };
    } catch (error) {
      const errorMessage = error.message || '创建情侣空间失败';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 加入情侣空间
  const joinCouple = async (inviteCode) => {
    try {
      setLoading(true);
      const response = await coupleAPI.join(inviteCode);
      const joinedCouple = response.data.couple;
      
      setCouple(joinedCouple);
      return { success: true, couple: joinedCouple };
    } catch (error) {
      const errorMessage = error.message || '加入情侣空间失败';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 更新情侣空间
  const updateCouple = async (data) => {
    try {
      setLoading(true);
      const response = await coupleAPI.update(data);
      const updatedCouple = response.data.couple;
      
      setCouple(updatedCouple);
      return { success: true, couple: updatedCouple };
    } catch (error) {
      const errorMessage = error.message || '更新情侣空间失败';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 解除情侣关系
  const deleteCouple = async () => {
    try {
      setLoading(true);
      await coupleAPI.delete();
      setCouple(null);
      return { success: true };
    } catch (error) {
      const errorMessage = error.message || '解除关系失败';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  // 检查是否已认证
  const isAuthenticated = !!user;
  
  // 检查是否有情侣空间
  const hasCouple = !!couple;
  
  // 获取伴侣信息
  const getPartner = () => {
    if (!couple || !user) return null;
    
    const isUser1 = couple.user1_id === user.id;
    return {
      id: isUser1 ? couple.user2_id : couple.user1_id,
      name: isUser1 ? couple.user2_name : couple.user1_name,
      email: isUser1 ? couple.user2_email : couple.user1_email
    };
  };

  const value = {
    // 状态
    user,
    couple,
    loading,
    error,
    isAuthenticated,
    hasCouple,
    
    // 方法
    register,
    login,
    logout,
    updateProfile,
    createCouple,
    joinCouple,
    updateCouple,
    deleteCouple,
    loadCoupleInfo,
    getPartner,
    
    // 工具方法
    clearError: () => setError(null)
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};