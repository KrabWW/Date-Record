// 统一错误处理中间件
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // 数据库错误
  if (err.code === 'SQLITE_CONSTRAINT') {
    return res.status(400).json({
      error: '数据约束违反',
      message: '请检查输入数据是否重复或无效'
    });
  }

  if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
    return res.status(400).json({
      error: '数据重复',
      message: '该邮箱或邀请码已存在'
    });
  }

  // JWT错误
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: '认证失败',
      message: '令牌无效'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: '认证失败',
      message: '令牌已过期'
    });
  }

  // 文件上传错误
  if (err.code === 'MULTER_FILE_TOO_LARGE') {
    return res.status(400).json({
      error: '文件太大',
      message: '请选择小于5MB的图片'
    });
  }

  if (err.code === 'INVALID_FILE_TYPE') {
    return res.status(400).json({
      error: '文件类型不支持',
      message: '只支持 JPG、PNG、GIF 格式的图片'
    });
  }

  // 验证错误
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: '数据验证失败',
      message: err.message
    });
  }

  // 默认服务器错误
  res.status(500).json({
    error: '服务器内部错误',
    message: process.env.NODE_ENV === 'development' ? err.message : '请稍后重试'
  });
};

// 404错误处理
const notFound = (req, res, next) => {
  const error = new Error(`未找到 - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

module.exports = {
  errorHandler,
  notFound
};