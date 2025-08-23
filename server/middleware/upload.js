const multer = require('multer');
const path = require('path');
const fs = require('fs');

// 确保上传目录存在
const uploadDir = path.join(__dirname, '..', process.env.UPLOAD_PATH || 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// 存储配置
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // 生成唯一文件名：时间戳_随机数_原文件名
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueSuffix}${ext}`);
  }
});

// 文件过滤器
const fileFilter = (req, file, cb) => {
  // 只允许图片类型
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    const error = new Error('只支持 JPG、PNG、GIF、WebP 格式的图片');
    error.code = 'INVALID_FILE_TYPE';
    cb(error, false);
  }
};

// 上传配置
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024, // 5MB
    files: 5 // 最多5个文件
  }
});

// 单个文件上传中间件
const uploadSingle = upload.single('photo');

// 多个文件上传中间件
const uploadMultiple = upload.array('photos', 5);

// 删除文件的辅助函数
const deleteFile = (filename) => {
  const filePath = path.join(uploadDir, filename);
  fs.unlink(filePath, (err) => {
    if (err) {
      console.error('删除文件失败:', err);
    } else {
      console.log('文件删除成功:', filename);
    }
  });
};

module.exports = {
  uploadSingle,
  uploadMultiple,
  deleteFile,
  uploadDir
};