const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// 基础安全配置
const securityConfig = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "blob:"],
    },
  },
});

// 通用限流配置
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: parseInt(process.env.GENERAL_LIMIT) || 100, // 最多100个请求
  message: {
    error: '请求过于频繁',
    message: '请稍后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 登录限流配置（更严格）
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: parseInt(process.env.LOGIN_LIMIT) || 5, // 最多5次登录尝试
  message: {
    error: '登录尝试次数过多',
    message: '请15分钟后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 注册限流配置
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1小时
  max: parseInt(process.env.REGISTER_LIMIT) || 3, // 最多3次注册尝试
  message: {
    error: '注册尝试次数过多',
    message: '请1小时后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// 上传限流配置
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: parseInt(process.env.UPLOAD_LIMIT) || 20, // 最多20次上传
  message: {
    error: '上传过于频繁',
    message: '请稍后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  securityConfig,
  generalLimiter,
  loginLimiter,
  registerLimiter,
  uploadLimiter
};