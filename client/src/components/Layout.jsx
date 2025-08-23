import React from 'react';
import { useLocation } from 'react-router-dom';
import BottomNavigation from './BottomNavigation';
import TopHeader from './TopHeader';

const Layout = ({ children }) => {
  const location = useLocation();
  
  return (
    <div className="page-container">
      {/* 顶部导航 */}
      <TopHeader />
      
      {/* 主要内容区域 */}
      <main className="content-container">
        {children}
      </main>
      
      {/* 底部导航 */}
      <BottomNavigation />
    </div>
  );
};

export default Layout;