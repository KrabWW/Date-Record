import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Eye, EyeOff, Heart } from 'lucide-react';

const AuthPage = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { login, register } = useAuth();

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // 清除错误信息
    if (error) setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const result = isLogin 
        ? await login({ email: formData.email, password: formData.password })
        : await register(formData);

      if (!result.success) {
        setError(result.error);
      }
    } catch (error) {
      setError('网络错误，请稍后重试');
    } finally {
      setIsLoading(false);
    }
  };

  const toggleMode = () => {
    setIsLogin(!isLogin);
    setError('');
    setFormData({
      email: '',
      password: '',
      name: ''
    });
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo和标题 */}
        <div className="text-center mb-8">
          <div className="mb-4">
            <Heart className="w-16 h-16 mx-auto text-love-pink animate-heartbeat" />
          </div>
          <h1 className="text-3xl font-display font-bold gradient-text">
            Love4Lili
          </h1>
          <p className="text-gray-600 mt-2">
            记录你们的美好时光
          </p>
        </div>

        {/* 登录/注册表单 */}
        <div className="card">
          <div className="flex mb-6">
            <button
              type="button"
              onClick={() => setIsLogin(true)}
              className={`flex-1 py-2 px-4 text-center rounded-lg transition-all duration-200 ${
                isLogin
                  ? 'bg-love-pink text-white'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              登录
            </button>
            <button
              type="button"
              onClick={() => setIsLogin(false)}
              className={`flex-1 py-2 px-4 text-center rounded-lg transition-all duration-200 ${
                !isLogin
                  ? 'bg-love-pink text-white'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              注册
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* 姓名输入（仅注册时显示） */}
            {!isLogin && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  姓名
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  className="input-field"
                  placeholder="请输入您的姓名"
                  required
                />
              </div>
            )}

            {/* 邮箱输入 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                邮箱
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                className="input-field"
                placeholder="请输入邮箱地址"
                required
              />
            </div>

            {/* 密码输入 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                密码
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  className="input-field pr-10"
                  placeholder={isLogin ? '请输入密码' : '请设置密码（至少6位）'}
                  minLength={isLogin ? undefined : 6}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {/* 错误信息 */}
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                <p className="text-red-600 text-sm">{error}</p>
              </div>
            )}

            {/* 提交按钮 */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <div className="loading-spinner mr-2"></div>
                  {isLogin ? '登录中...' : '注册中...'}
                </div>
              ) : (
                isLogin ? '登录' : '创建账户'
              )}
            </button>
          </form>

          {/* 切换模式提示 */}
          <div className="mt-6 text-center text-sm text-gray-600">
            {isLogin ? '还没有账户？' : '已有账户？'}
            <button
              type="button"
              onClick={toggleMode}
              className="ml-1 text-love-pink hover:text-love-pink-dark font-medium"
            >
              {isLogin ? '立即注册' : '立即登录'}
            </button>
          </div>
        </div>

        {/* 说明文字 */}
        <div className="mt-8 text-center text-xs text-gray-500">
          <p>注册即表示您同意我们的服务条款和隐私政策</p>
        </div>
      </div>
    </div>
  );
};

export default AuthPage;