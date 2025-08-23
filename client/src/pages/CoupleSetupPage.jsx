import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Heart, Copy, Check } from 'lucide-react';

const CoupleSetupPage = () => {
  const [mode, setMode] = useState('choose'); // 'choose', 'create', 'join'
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [copied, setCopied] = useState(false);
  
  const [createData, setCreateData] = useState({
    couple_name: '',
    anniversary_date: ''
  });
  
  const [joinData, setJoinData] = useState({
    invite_code: ''
  });
  
  const [createdCouple, setCreatedCouple] = useState(null);
  
  const { createCouple, joinCouple, user } = useAuth();

  const handleCreateCouple = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    
    try {
      const result = await createCouple(createData);
      if (result.success) {
        setCreatedCouple(result.couple);
        setSuccess('情侣空间创建成功！请将邀请码分享给您的伴侣');
      } else {
        setError(result.error);
      }
    } catch (error) {
      setError('创建失败，请稍后重试');
    } finally {
      setIsLoading(false);
    }
  };

  const handleJoinCouple = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    
    try {
      const result = await joinCouple(joinData.invite_code);
      if (result.success) {
        setSuccess('成功加入情侣空间！');
      } else {
        setError(result.error);
      }
    } catch (error) {
      setError('加入失败，请检查邀请码是否正确');
    } finally {
      setIsLoading(false);
    }
  };

  const copyInviteCode = async () => {
    if (createdCouple?.invite_code) {
      try {
        await navigator.clipboard.writeText(createdCouple.invite_code);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      } catch (error) {
        // 降级方案：选择文本
        const textArea = document.createElement('textarea');
        textArea.value = createdCouple.invite_code;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }
    }
  };

  const renderChooseMode = () => (
    <div className="text-center">
      <div className="mb-8">
        <Heart className="w-20 h-20 mx-auto text-love-pink animate-heartbeat" />
      </div>
      
      <h1 className="text-3xl font-display font-bold gradient-text mb-4">
        欢迎 {user?.name}！
      </h1>
      <p className="text-gray-600 mb-8">
        让我们创建您的爱情空间
      </p>
      
      <div className="space-y-4">
        <button
          onClick={() => setMode('create')}
          className="w-full btn-primary"
        >
          🎉 创建新的情侣空间
        </button>
        
        <button
          onClick={() => setMode('join')}
          className="w-full btn-secondary"
        >
          💕 加入伴侣的空间
        </button>
      </div>
    </div>
  );

  const renderCreateMode = () => (
    <div>
      <div className="text-center mb-8">
        <h2 className="text-2xl font-display font-bold text-gray-800 mb-2">
          创建情侣空间
        </h2>
        <p className="text-gray-600">
          为你们的爱情故事命名
        </p>
      </div>

      {createdCouple ? (
        <div className="card text-center">
          <div className="mb-6">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Check className="w-8 h-8 text-green-600" />
            </div>
            <h3 className="text-xl font-semibold text-gray-800 mb-2">
              创建成功！
            </h3>
            <p className="text-gray-600">
              {createdCouple.couple_name} 已创建
            </p>
          </div>

          <div className="bg-gray-50 rounded-lg p-4 mb-6">
            <p className="text-sm text-gray-600 mb-2">邀请码</p>
            <div className="flex items-center justify-center space-x-2">
              <code className="text-2xl font-mono font-bold text-love-pink tracking-wider">
                {createdCouple.invite_code}
              </code>
              <button
                onClick={copyInviteCode}
                className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100"
              >
                {copied ? <Check className="w-5 h-5 text-green-600" /> : <Copy className="w-5 h-5" />}
              </button>
            </div>
            <p className="text-xs text-gray-500 mt-2">
              {copied ? '已复制到剪贴板' : '点击复制邀请码'}
            </p>
          </div>

          <p className="text-sm text-gray-600 mb-6">
            请将邀请码发送给您的伴侣，他们可以使用邀请码加入这个空间
          </p>
        </div>
      ) : (
        <form onSubmit={handleCreateCouple} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              情侣空间名称
            </label>
            <input
              type="text"
              value={createData.couple_name}
              onChange={(e) => setCreateData(prev => ({
                ...prev,
                couple_name: e.target.value
              }))}
              className="input-field"
              placeholder="例如：小明 & 小红的爱情空间"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              纪念日（可选）
            </label>
            <input
              type="date"
              value={createData.anniversary_date}
              onChange={(e) => setCreateData(prev => ({
                ...prev,
                anniversary_date: e.target.value
              }))}
              className="input-field"
            />
            <p className="text-xs text-gray-500 mt-1">
              设置你们的纪念日，比如初次约会或确定关系的日期
            </p>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full btn-primary disabled:opacity-50"
          >
            {isLoading ? '创建中...' : '创建空间'}
          </button>
        </form>
      )}

      <button
        onClick={() => setMode('choose')}
        className="w-full btn-ghost mt-4"
      >
        返回
      </button>
    </div>
  );

  const renderJoinMode = () => (
    <div>
      <div className="text-center mb-8">
        <h2 className="text-2xl font-display font-bold text-gray-800 mb-2">
          加入情侣空间
        </h2>
        <p className="text-gray-600">
          输入伴侣分享的邀请码
        </p>
      </div>

      <form onSubmit={handleJoinCouple} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            邀请码
          </label>
          <input
            type="text"
            value={joinData.invite_code}
            onChange={(e) => setJoinData(prev => ({
              ...prev,
              invite_code: e.target.value.toUpperCase()
            }))}
            className="input-field text-center text-xl font-mono tracking-wider"
            placeholder="输入8位邀请码"
            maxLength={8}
            required
          />
          <p className="text-xs text-gray-500 mt-1">
            邀请码由8位大写字母和数字组成
          </p>
        </div>

        <button
          type="submit"
          disabled={isLoading || joinData.invite_code.length !== 8}
          className="w-full btn-primary disabled:opacity-50"
        >
          {isLoading ? '加入中...' : '加入空间'}
        </button>
      </form>

      <button
        onClick={() => setMode('choose')}
        className="w-full btn-ghost mt-4"
      >
        返回
      </button>
    </div>
  );

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="card">
          {/* 错误信息 */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-6">
              <p className="text-red-600 text-sm">{error}</p>
            </div>
          )}

          {/* 成功信息 */}
          {success && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-3 mb-6">
              <p className="text-green-600 text-sm">{success}</p>
            </div>
          )}

          {/* 渲染不同模式 */}
          {mode === 'choose' && renderChooseMode()}
          {mode === 'create' && renderCreateMode()}
          {mode === 'join' && renderJoinMode()}
        </div>
      </div>
    </div>
  );
};

export default CoupleSetupPage;