require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');

// 中间件导入
const { securityConfig, generalLimiter } = require('./middleware/security');
const { errorHandler, notFound } = require('./middleware/errorHandler');

// 路由导入
const authRoutes = require('./routes/auth');
const coupleRoutes = require('./routes/couples');
const recordRoutes = require('./routes/records');
const wishlistRoutes = require('./routes/wishlists');
const uploadRoutes = require('./routes/upload');

const app = express();
const PORT = process.env.PORT || 8888;

// 基础安全中间件
app.use(securityConfig);

// CORS配置
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : (process.env.NODE_ENV === 'production' 
    ? ['https://yourdomain.com'] // 生产环境域名
    : ['http://localhost:5173', 'http://localhost:3000']); // 开发环境

app.use(cors({
  origin: allowedOrigins,
  credentials: true,
  optionsSuccessStatus: 200
}));

// 通用限流
app.use(generalLimiter);

// 请求解析中间件
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 静态文件服务（上传的图片）
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API路由
app.use('/api/auth', authRoutes);
app.use('/api/couples', coupleRoutes);
app.use('/api/records', recordRoutes);
app.use('/api/wishlists', wishlistRoutes);
app.use('/api/upload', uploadRoutes);

// API根路径
app.get('/api', (req, res) => {
  res.json({
    message: 'Love4Lili API Server',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      couples: '/api/couples',
      records: '/api/records',
      wishlists: '/api/wishlists',
      upload: '/api/upload'
    }
  });
});

// 生产环境下提供前端静态文件
if (process.env.NODE_ENV === 'production') {
  // 静态文件目录
  app.use(express.static(path.join(__dirname, '..', 'client', 'dist')));
  
  // 所有非API路由都返回React应用
  app.get('*', (req, res) => {
    if (!req.path.startsWith('/api') && !req.path.startsWith('/uploads')) {
      res.sendFile(path.join(__dirname, '..', 'client', 'dist', 'index.html'));
    } else {
      res.status(404).json({ error: 'API endpoint not found' });
    }
  });
}

// 404处理
app.use(notFound);

// 错误处理中间件
app.use(errorHandler);

// 优雅关闭处理
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

// 启动服务器
const server = app.listen(PORT, () => {
  console.log(`
🚀 Love4Lili Server is running!
📍 Port: ${PORT}
🌐 Environment: ${process.env.NODE_ENV || 'development'}
📋 API Documentation: http://localhost:${PORT}/api
🏥 Health Check: http://localhost:${PORT}/health
⏰ Started at: ${new Date().toLocaleString()}
  `);
});

module.exports = app;