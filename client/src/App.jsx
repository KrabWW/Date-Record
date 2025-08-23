import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';

// 页面组件
import LoadingScreen from './components/LoadingScreen';
import AuthPage from './pages/AuthPage';
import HomePage from './pages/HomePage';
import RecordsPage from './pages/RecordsPage';
import RecordDetailPage from './pages/RecordDetailPage';
import RecordEditPage from './pages/RecordEditPage';
import WishlistPage from './pages/WishlistPage';
import GalleryPage from './pages/GalleryPage';
import SettingsPage from './pages/SettingsPage';
import ProfilePage from './pages/ProfilePage';
import CoupleSetupPage from './pages/CoupleSetupPage';

// 布局组件
import Layout from './components/Layout';

function App() {
  const { user, couple, loading, isAuthenticated, hasCouple } = useAuth();

  // 加载状态
  if (loading) {
    return <LoadingScreen />;
  }

  // 未认证用户显示登录页面
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-love-cream">
        <Routes>
          <Route path="/auth" element={<AuthPage />} />
          <Route path="*" element={<Navigate to="/auth" replace />} />
        </Routes>
      </div>
    );
  }

  // 完整的应用界面（允许单人使用，情侣空间设置为可选）
  return (
    <div className="min-h-screen bg-love-cream">
      <Layout>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/records" element={<RecordsPage />} />
          <Route path="/records/new" element={<RecordEditPage />} />
          <Route path="/records/:id" element={<RecordDetailPage />} />
          <Route path="/records/:id/edit" element={<RecordEditPage />} />
          <Route path="/wishlist" element={<WishlistPage />} />
          <Route path="/gallery" element={<GalleryPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/couple-setup" element={<CoupleSetupPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Layout>
    </div>
  );
}

export default App;