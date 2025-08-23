const express = require('express');
const { dbAsync, generateInviteCode } = require('../models/database');
const { authenticateToken, validateCoupleAccess } = require('../middleware/auth');

const router = express.Router();

// 创建情侣空间
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const { couple_name, anniversary_date } = req.body;
    const userId = req.user.id;

    // 输入验证
    if (!couple_name) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写情侣空间名称'
      });
    }

    // 检查用户是否已经有情侣空间
    const existingCouple = await dbAsync.get(
      'SELECT id FROM couples WHERE (user1_id = ? OR user2_id = ?) AND is_active = 1',
      [userId, userId]
    );

    if (existingCouple) {
      return res.status(400).json({
        error: '已有情侣空间',
        message: '您已经创建或加入了情侣空间'
      });
    }

    // 生成唯一邀请码
    let inviteCode;
    let isUnique = false;
    let attempts = 0;

    while (!isUnique && attempts < 5) {
      inviteCode = generateInviteCode();
      const existingCode = await dbAsync.get(
        'SELECT id FROM couples WHERE invite_code = ?',
        [inviteCode]
      );
      isUnique = !existingCode;
      attempts++;
    }

    if (!isUnique) {
      return res.status(500).json({
        error: '创建失败',
        message: '无法生成唯一邀请码，请重试'
      });
    }

    // 创建情侣空间
    const result = await dbAsync.run(
      'INSERT INTO couples (user1_id, couple_name, invite_code, anniversary_date) VALUES (?, ?, ?, ?)',
      [userId, couple_name, inviteCode, anniversary_date]
    );

    // 获取创建的情侣空间信息
    const couple = await dbAsync.get(
      `SELECT c.*, u1.name as user1_name, u1.email as user1_email,
              u2.name as user2_name, u2.email as user2_email
       FROM couples c
       LEFT JOIN users u1 ON c.user1_id = u1.id
       LEFT JOIN users u2 ON c.user2_id = u2.id
       WHERE c.id = ?`,
      [result.id]
    );

    res.status(201).json({
      message: '情侣空间创建成功',
      couple
    });
  } catch (error) {
    next(error);
  }
});

// 通过邀请码加入情侣空间
router.post('/join', authenticateToken, async (req, res, next) => {
  try {
    const { invite_code } = req.body;
    const userId = req.user.id;

    // 输入验证
    if (!invite_code) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请输入邀请码'
      });
    }

    // 检查用户是否已经有情侣空间
    const existingCouple = await dbAsync.get(
      'SELECT id FROM couples WHERE (user1_id = ? OR user2_id = ?) AND is_active = 1',
      [userId, userId]
    );

    if (existingCouple) {
      return res.status(400).json({
        error: '已有情侣空间',
        message: '您已经创建或加入了情侣空间'
      });
    }

    // 查找邀请码对应的情侣空间
    const couple = await dbAsync.get(
      'SELECT * FROM couples WHERE invite_code = ? AND is_active = 1',
      [invite_code]
    );

    if (!couple) {
      return res.status(404).json({
        error: '邀请码无效',
        message: '未找到对应的情侣空间'
      });
    }

    // 检查是否已经有两个用户
    if (couple.user2_id) {
      return res.status(400).json({
        error: '空间已满',
        message: '该情侣空间已有两个用户'
      });
    }

    // 不能加入自己创建的空间
    if (couple.user1_id === userId) {
      return res.status(400).json({
        error: '无法加入',
        message: '不能加入自己创建的空间'
      });
    }

    // 加入情侣空间
    await dbAsync.run(
      'UPDATE couples SET user2_id = ? WHERE id = ?',
      [userId, couple.id]
    );

    // 获取更新后的情侣空间信息
    const updatedCouple = await dbAsync.get(
      `SELECT c.*, u1.name as user1_name, u1.email as user1_email,
              u2.name as user2_name, u2.email as user2_email
       FROM couples c
       LEFT JOIN users u1 ON c.user1_id = u1.id
       LEFT JOIN users u2 ON c.user2_id = u2.id
       WHERE c.id = ?`,
      [couple.id]
    );

    res.json({
      message: '加入情侣空间成功',
      couple: updatedCouple
    });
  } catch (error) {
    next(error);
  }
});

// 获取当前用户的情侣空间
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const couple = await dbAsync.get(
      `SELECT c.*, u1.name as user1_name, u1.email as user1_email,
              u2.name as user2_name, u2.email as user2_email
       FROM couples c
       LEFT JOIN users u1 ON c.user1_id = u1.id
       LEFT JOIN users u2 ON c.user2_id = u2.id
       WHERE (c.user1_id = ? OR c.user2_id = ?) AND c.is_active = 1`,
      [userId, userId]
    );

    if (!couple) {
      return res.status(404).json({
        error: '未找到情侣空间',
        message: '您还没有创建或加入情侣空间'
      });
    }

    res.json({
      couple
    });
  } catch (error) {
    next(error);
  }
});

// 更新情侣空间信息
router.put('/me', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const { couple_name, anniversary_date } = req.body;
    const coupleId = req.couple.id;

    // 输入验证
    if (!couple_name) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '情侣空间名称不能为空'
      });
    }

    await dbAsync.run(
      'UPDATE couples SET couple_name = ?, anniversary_date = ? WHERE id = ?',
      [couple_name, anniversary_date, coupleId]
    );

    // 获取更新后的信息
    const updatedCouple = await dbAsync.get(
      `SELECT c.*, u1.name as user1_name, u1.email as user1_email,
              u2.name as user2_name, u2.email as user2_email
       FROM couples c
       LEFT JOIN users u1 ON c.user1_id = u1.id
       LEFT JOIN users u2 ON c.user2_id = u2.id
       WHERE c.id = ?`,
      [coupleId]
    );

    res.json({
      message: '情侣空间信息更新成功',
      couple: updatedCouple
    });
  } catch (error) {
    next(error);
  }
});

// 解除情侣关系（软删除）
router.delete('/me', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const coupleId = req.couple.id;

    await dbAsync.run(
      'UPDATE couples SET is_active = 0 WHERE id = ?',
      [coupleId]
    );

    res.json({
      message: '已解除情侣关系'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;