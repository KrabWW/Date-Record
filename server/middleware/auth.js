const jwt = require('jsonwebtoken');
const { dbAsync } = require('../models/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// 验证token中间件
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: '访问令牌缺失' });
    }

    // 验证token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // 从数据库获取用户信息
    const user = await dbAsync.get(
      'SELECT id, email, name, avatar_url FROM users WHERE id = ?',
      [decoded.userId]
    );

    if (!user) {
      return res.status(401).json({ error: '用户不存在' });
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(403).json({ error: '令牌无效' });
    } else if (error.name === 'TokenExpiredError') {
      return res.status(403).json({ error: '令牌已过期' });
    } else {
      console.error('Auth middleware error:', error);
      return res.status(500).json({ error: '服务器内部错误' });
    }
  }
};

// 生成JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    JWT_SECRET,
    { expiresIn: '7d' } // 7天过期
  );
};

// 验证情侣空间访问权限
const validateCoupleAccess = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    // 获取用户的情侣空间
    const couple = await dbAsync.get(
      'SELECT * FROM couples WHERE (user1_id = ? OR user2_id = ?) AND is_active = 1',
      [userId, userId]
    );

    if (!couple) {
      return res.status(404).json({ error: '未找到情侣空间' });
    }

    req.couple = couple;
    next();
  } catch (error) {
    console.error('Couple access validation error:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
};

module.exports = {
  authenticateToken,
  generateToken,
  validateCoupleAccess
};