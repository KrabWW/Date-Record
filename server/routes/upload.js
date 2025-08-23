const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegStatic = require('ffmpeg-static');
const { authenticateToken } = require('../middleware/auth');
const sqlite3 = require('sqlite3').verbose();

const router = express.Router();

// 设置ffmpeg路径
ffmpeg.setFfmpegPath(ffmpegStatic);

// 数据库连接
const dbPath = path.join(__dirname, '..', 'database.db');
const db = new sqlite3.Database(dbPath);

// 存储空间限制常量
const STORAGE_LIMITS = {
  FREE: 1 * 1024 * 1024 * 1024,      // 免费用户: 1GB
  VIP: 10 * 1024 * 1024 * 1024,      // VIP用户: 10GB
};

const FILE_SIZE_LIMITS = {
  PHOTO: {
    FREE: 10 * 1024 * 1024,          // 免费用户照片: 10MB
    VIP: 20 * 1024 * 1024,           // VIP用户照片: 20MB
  },
  VIDEO: {
    FREE: 100 * 1024 * 1024,         // 免费用户视频: 100MB
    VIP: 500 * 1024 * 1024,          // VIP用户视频: 500MB
  }
};

// 配置存储
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = file.mimetype.startsWith('video/') ? 'uploads/videos' : 'uploads/photos';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// 文件类型过滤
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
    cb(null, true);
  } else {
    cb(new Error('只支持图片和视频文件'), false);
  }
};

// 动态文件大小限制
const dynamicLimits = (req, res, next) => {
  // 获取用户VIP状态（这里简化处理，实际应该从数据库获取）
  const isVip = req.user?.isVip || false;
  
  req.fileLimits = {
    photo: isVip ? FILE_SIZE_LIMITS.PHOTO.VIP : FILE_SIZE_LIMITS.PHOTO.FREE,
    video: isVip ? FILE_SIZE_LIMITS.VIDEO.VIP : FILE_SIZE_LIMITS.VIDEO.FREE
  };
  next();
};

// 配置multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 500 * 1024 * 1024 // 最大500MB，具体限制在中间件中处理
  }
});

// 检查用户存储空间
const checkStorageLimit = async (userId, fileSize) => {
  return new Promise((resolve, reject) => {
    const userQuery = `SELECT is_vip, used_storage FROM users WHERE id = ?`;
    db.get(userQuery, [userId], (err, row) => {
      if (err) {
        reject(err);
        return;
      }

      const user = row || { is_vip: false, used_storage: 0 };
      const isVipActive = user.is_vip || false;
      const maxStorage = isVipActive ? STORAGE_LIMITS.VIP : STORAGE_LIMITS.FREE;
      const usedStorage = user.used_storage || 0;

      if (usedStorage + fileSize > maxStorage) {
        reject(new Error(`存储空间不足。${isVipActive ? 'VIP用户' : '免费用户'}最大存储: ${maxStorage / (1024 * 1024 * 1024)}GB`));
      } else {
        resolve(true);
      }
    });
  });
};

// 更新用户已使用存储空间
const updateUsedStorage = async (userId, fileSize) => {
  return new Promise((resolve, reject) => {
    const updateQuery = `UPDATE users SET used_storage = COALESCE(used_storage, 0) + ? WHERE id = ?`;
    db.run(updateQuery, [fileSize, userId], (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
};

// 生成视频缩略图
const generateThumbnail = (videoPath, outputPath) => {
  return new Promise((resolve, reject) => {
    ffmpeg(videoPath)
      .screenshots({
        timestamps: ['50%'],
        filename: path.basename(outputPath),
        folder: path.dirname(outputPath),
        size: '320x240'
      })
      .on('end', () => resolve(outputPath))
      .on('error', reject);
  });
};

// 获取视频时长
const getVideoDuration = (videoPath) => {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(videoPath, (err, metadata) => {
      if (err) reject(err);
      else resolve(Math.floor(metadata.format.duration));
    });
  });
};

// 照片上传
router.post('/photo', authenticateToken, dynamicLimits, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: '请选择图片文件' });
    }

    // 检查文件大小
    if (req.file.size > req.fileLimits.photo) {
      fs.unlinkSync(req.file.path); // 删除文件
      return res.status(400).json({ 
        error: `图片文件太大，最大允许 ${req.fileLimits.photo / (1024 * 1024)}MB` 
      });
    }

    // 检查存储限制
    await checkStorageLimit(req.user.id, req.file.size);

    const mediaData = {
      couple_id: req.body.couple_id,
      record_id: req.body.record_id || null,
      file_url: req.file.path,
      file_type: 'photo',
      caption: req.body.caption || null,
      file_size: req.file.size,
      mime_type: req.file.mimetype
    };

    const query = `INSERT INTO media (couple_id, record_id, file_url, file_type, caption, file_size, mime_type) 
                   VALUES (?, ?, ?, ?, ?, ?, ?)`;
    
    const mediaId = await new Promise((resolve, reject) => {
      db.run(query, Object.values(mediaData), function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      });
    });

    // 更新存储使用量
    await updateUsedStorage(req.user.id, req.file.size);

    // 构造可访问的文件URL
    const fileUrl = `/${req.file.path.replace(/\\/g, '/')}`; // 确保使用正斜杠，兼容Windows
    
    res.json({ 
      success: true, 
      mediaId,
      fileUrl: fileUrl,
      fileType: 'photo'
    });

  } catch (error) {
    // 删除已上传的文件
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(400).json({ error: error.message });
  }
});

// 视频上传
router.post('/video', authenticateToken, dynamicLimits, upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: '请选择视频文件' });
    }

    // 检查文件大小
    if (req.file.size > req.fileLimits.video) {
      fs.unlinkSync(req.file.path); // 删除文件
      return res.status(400).json({ 
        error: `视频文件太大，最大允许 ${req.fileLimits.video / (1024 * 1024)}MB` 
      });
    }

    // 检查存储限制
    await checkStorageLimit(req.user.id, req.file.size);

    // 获取视频时长
    const duration = await getVideoDuration(req.file.path);
    
    // 生成缩略图
    const thumbnailPath = req.file.path.replace(path.extname(req.file.path), '_thumb.jpg');
    await generateThumbnail(req.file.path, thumbnailPath);

    const mediaData = {
      couple_id: req.body.couple_id,
      record_id: req.body.record_id || null,
      file_url: req.file.path,
      file_type: 'video',
      caption: req.body.caption || null,
      file_size: req.file.size,
      mime_type: req.file.mimetype,
      duration: duration,
      thumbnail_url: thumbnailPath
    };

    const query = `INSERT INTO media (couple_id, record_id, file_url, file_type, caption, file_size, mime_type, duration, thumbnail_url) 
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`;
    
    const mediaId = await new Promise((resolve, reject) => {
      db.run(query, Object.values(mediaData), function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      });
    });

    // 更新存储使用量（包括缩略图）
    const thumbnailSize = fs.existsSync(thumbnailPath) ? fs.statSync(thumbnailPath).size : 0;
    await updateUsedStorage(req.user.id, req.file.size + thumbnailSize);

    // 构造可访问的文件URL
    const fileUrl = `/${req.file.path.replace(/\\/g, '/')}`; // 确保使用正斜杠，兼容Windows
    const thumbnailUrl = `/${thumbnailPath.replace(/\\/g, '/')}`;
    
    res.json({ 
      success: true, 
      mediaId,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      fileType: 'video',
      duration: duration
    });

  } catch (error) {
    // 删除已上传的文件
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(400).json({ error: error.message });
  }
});

// 获取媒体文件列表
router.get('/media/:recordId?', authenticateToken, async (req, res) => {
  try {
    const { recordId } = req.params;
    const userId = req.user.id;
    
    let query, params;
    
    if (recordId) {
      // 获取特定记录的媒体文件
      query = `SELECT m.* FROM media m 
               INNER JOIN records r ON m.record_id = r.id 
               INNER JOIN couples c ON r.couple_id = c.id 
               WHERE m.record_id = ? AND (c.user1_id = ? OR c.user2_id = ?)
               ORDER BY m.created_at DESC`;
      params = [recordId, userId, userId];
    } else {
      // 获取用户情侣空间的所有媒体文件
      query = `SELECT m.* FROM media m 
               INNER JOIN couples c ON m.couple_id = c.id 
               WHERE c.user1_id = ? OR c.user2_id = ?
               ORDER BY m.created_at DESC`;
      params = [userId, userId];
    }

    db.all(query, params, (err, rows) => {
      if (err) {
        console.error('Database error:', err);
        res.status(500).json({ error: '获取媒体文件失败' });
      } else {
        res.json({ data: rows });
      }
    });
  } catch (error) {
    console.error('Error getting media:', error);
    res.status(500).json({ error: error.message });
  }
});

// 删除媒体文件
router.delete('/media/:mediaId', authenticateToken, async (req, res) => {
  try {
    const { mediaId } = req.params;
    
    // 获取文件信息
    const media = await new Promise((resolve, reject) => {
      db.get('SELECT * FROM media WHERE id = ?', [mediaId], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!media) {
      return res.status(404).json({ error: '媒体文件不存在' });
    }

    // 删除物理文件
    if (fs.existsSync(media.file_url)) {
      fs.unlinkSync(media.file_url);
    }
    if (media.thumbnail_url && fs.existsSync(media.thumbnail_url)) {
      fs.unlinkSync(media.thumbnail_url);
    }

    // 删除数据库记录
    await new Promise((resolve, reject) => {
      db.run('DELETE FROM media WHERE id = ?', [mediaId], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    // 更新存储使用量
    const thumbnailSize = media.thumbnail_url && fs.existsSync(media.thumbnail_url) 
      ? fs.statSync(media.thumbnail_url).size : 0;
    const totalSize = media.file_size + thumbnailSize;
    await updateUsedStorage(req.user.id, -totalSize);

    res.json({ success: true });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 获取用户存储信息
router.get('/storage-info', authenticateToken, (req, res) => {
  const userId = req.user.id;
  
  const query = `SELECT is_vip, used_storage, vip_expires_at FROM users WHERE id = ?`;
  db.get(query, [userId], (err, user) => {
    if (err) {
      return res.status(500).json({ error: '获取存储信息失败' });
    }

    const isVipActive = user.is_vip && (!user.vip_expires_at || new Date(user.vip_expires_at) > new Date());
    const maxStorage = isVipActive ? STORAGE_LIMITS.VIP : STORAGE_LIMITS.FREE;
    const usedStorage = user.used_storage || 0;

    res.json({
      isVip: isVipActive,
      maxStorage,
      usedStorage,
      availableStorage: maxStorage - usedStorage,
      usagePercentage: Math.round((usedStorage / maxStorage) * 100),
      limits: {
        photoSize: isVipActive ? FILE_SIZE_LIMITS.PHOTO.VIP : FILE_SIZE_LIMITS.PHOTO.FREE,
        videoSize: isVipActive ? FILE_SIZE_LIMITS.VIDEO.VIP : FILE_SIZE_LIMITS.VIDEO.FREE,
      }
    });
  });
});

module.exports = router;