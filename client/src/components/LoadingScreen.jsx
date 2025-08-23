import React from 'react';

const LoadingScreen = () => {
  return (
    <div className="min-h-screen bg-love-cream flex items-center justify-center">
      <div className="text-center">
        {/* 爱心加载动画 */}
        <div className="mb-6">
          <svg 
            className="w-16 h-16 mx-auto text-love-pink animate-heartbeat" 
            fill="currentColor" 
            viewBox="0 0 64 64"
          >
            <path d="M32 54C32 54 8 42 8 24C8 18.4772 12.4772 14 18 14C22.4183 14 26.1829 16.5357 28 20.1433C29.8171 16.5357 33.5817 14 38 14C43.5228 14 48 18.4772 48 24C48 42 32 54 32 54Z" />
          </svg>
        </div>
        
        <h2 className="text-2xl font-display font-semibold text-gray-800 mb-2">
          Love4Lili
        </h2>
        <p className="text-gray-600 mb-6">
          加载中，请稍候...
        </p>
        
        {/* 加载指示器 */}
        <div className="flex justify-center">
          <div className="loading-spinner"></div>
        </div>
      </div>
    </div>
  );
};

export default LoadingScreen;