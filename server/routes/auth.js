const express = require('express');
const bcrypt = require('bcryptjs');
const { dbAsync } = require('../models/database');
const { generateToken, authenticateToken } = require('../middleware/auth');
const { loginLimiter, registerLimiter } = require('../middleware/security');

const router = express.Router();

// 注册
router.post('/register', registerLimiter, async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    // 输入验证
    if (!email || !password || !name) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写邮箱、密码和姓名'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        error: '密码太短',
        message: '密码至少需要6位'
      });
    }

    // 检查邮箱是否已存在
    const existingUser = await dbAsync.get(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUser) {
      return res.status(400).json({
        error: '邮箱已存在',
        message: '该邮箱已被注册，请使用其他邮箱'
      });
    }

    // 加密密码
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // 创建用户
    const result = await dbAsync.run(
      'INSERT INTO users (email, password_hash, name) VALUES (?, ?, ?)',
      [email, passwordHash, name]
    );

    // 生成token
    const token = generateToken(result.id);

    // 获取用户信息（不包含密码）
    const user = await dbAsync.get(
      'SELECT id, email, name, avatar_url, created_at FROM users WHERE id = ?',
      [result.id]
    );

    res.status(201).json({
      message: '注册成功',
      token,
      user
    });
  } catch (error) {
    next(error);
  }
});

// 登录
router.post('/login', /* loginLimiter */ async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // 输入验证
    if (!email || !password) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写邮箱和密码'
      });
    }

    // 查找用户
    const user = await dbAsync.get(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (!user) {
      return res.status(401).json({
        error: '登录失败',
        message: '邮箱或密码错误'
      });
    }

    // 验证密码
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        error: '登录失败',
        message: '邮箱或密码错误'
      });
    }

    // 生成token
    const token = generateToken(user.id);

    // 返回用户信息（不包含密码）
    const { password_hash, ...userInfo } = user;

    res.json({
      message: '登录成功',
      token,
      user: userInfo
    });
  } catch (error) {
    next(error);
  }
});

// 验证token（获取当前用户信息）
router.get('/me', authenticateToken, async (req, res) => {
  try {
    res.json({
      user: req.user
    });
  } catch (error) {
    next(error);
  }
});

// 登出（客户端删除token即可，这里主要是为了统一接口）
router.post('/logout', authenticateToken, (req, res) => {
  res.json({
    message: '登出成功'
  });
});

// 更新用户信息
router.put('/profile', authenticateToken, async (req, res, next) => {
  try {
    const { name, avatar_url } = req.body;
    const userId = req.user.id;

    if (!name) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '姓名不能为空'
      });
    }

    await dbAsync.run(
      'UPDATE users SET name = ?, avatar_url = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [name, avatar_url, userId]
    );

    // 获取更新后的用户信息
    const updatedUser = await dbAsync.get(
      'SELECT id, email, name, avatar_url, created_at, updated_at FROM users WHERE id = ?',
      [userId]
    );

    res.json({
      message: '用户信息更新成功',
      user: updatedUser
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;