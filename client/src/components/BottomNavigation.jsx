import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { Home, Heart, Camera, User } from 'lucide-react';

const BottomNavigation = () => {
  const location = useLocation();
  
  const navItems = [
    {
      path: '/',
      label: '首页',
      icon: Home
    },
    {
      path: '/records',
      label: '记录',
      icon: Heart
    },
    {
      path: '/gallery',
      label: '相册',
      icon: Camera
    },
    {
      path: '/profile',
      label: '我的',
      icon: User
    }
  ];

  return (
    <nav className="bottom-nav">
      <div className="flex justify-around items-center h-16 max-w-lg mx-auto px-4">
        {navItems.map(({ path, label, icon: Icon }) => {
          const isActive = location.pathname === path || 
            (path !== '/' && location.pathname.startsWith(path));
          
          return (
            <NavLink
              key={path}
              to={path}
              aria-label={`导航到${label}页面`}
              className={`flex flex-col items-center justify-center space-y-1 p-2 rounded-lg transition-all duration-200 focus-visible min-h-[44px] min-w-[44px] ${
                isActive 
                  ? 'text-love-pink bg-love-pink bg-opacity-10' 
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              <Icon className={`w-5 h-5 ${isActive ? 'text-love-pink' : ''}`} />
              <span className={`text-xs font-medium ${isActive ? 'text-love-pink' : ''}`}>
                {label}
              </span>
            </NavLink>
          );
        })}
      </div>
    </nav>
  );
};

export default BottomNavigation;