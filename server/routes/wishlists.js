const express = require('express');
const { dbAsync } = require('../models/database');
const { authenticateToken, validateCoupleAccess } = require('../middleware/auth');

const router = express.Router();

// 获取愿望清单
router.get('/', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const coupleId = req.couple.id;
    const { completed = 'all', sort = 'priority_desc' } = req.query;

    // 构建WHERE条件
    let whereClause = 'couple_id = ?';
    const params = [coupleId];

    if (completed === 'true') {
      whereClause += ' AND is_completed = 1';
    } else if (completed === 'false') {
      whereClause += ' AND is_completed = 0';
    }

    // 确定排序方式
    let orderBy = 'priority DESC, created_at DESC';
    switch (sort) {
      case 'priority_asc':
        orderBy = 'priority ASC, created_at DESC';
        break;
      case 'created_desc':
        orderBy = 'created_at DESC';
        break;
      case 'created_asc':
        orderBy = 'created_at ASC';
        break;
      case 'target_date':
        orderBy = 'target_date ASC, priority DESC';
        break;
    }

    // 获取愿望清单
    const wishlists = await dbAsync.all(
      `SELECT * FROM wishlists 
       WHERE ${whereClause}
       ORDER BY ${orderBy}`,
      params
    );

    // 获取统计信息
    const stats = await dbAsync.get(
      `SELECT 
         COUNT(*) as total,
         SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed,
         SUM(CASE WHEN is_completed = 0 THEN 1 ELSE 0 END) as pending
       FROM wishlists WHERE couple_id = ?`,
      [coupleId]
    );

    res.json({
      wishlists,
      stats: {
        total: stats.total,
        completed: stats.completed,
        pending: stats.pending,
        completion_rate: stats.total > 0 ? ((stats.completed / stats.total) * 100).toFixed(1) : 0
      }
    });
  } catch (error) {
    next(error);
  }
});

// 获取单个愿望详情
router.get('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const wishlistId = req.params.id;
    const coupleId = req.couple.id;

    const wishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ? AND couple_id = ?',
      [wishlistId, coupleId]
    );

    if (!wishlist) {
      return res.status(404).json({
        error: '愿望不存在',
        message: '未找到指定的愿望项目'
      });
    }

    res.json({
      wishlist
    });
  } catch (error) {
    next(error);
  }
});

// 创建愿望
router.post('/', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const { title, description, priority = 3, target_date } = req.body;
    const coupleId = req.couple.id;

    // 输入验证
    if (!title) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写愿望标题'
      });
    }

    if (priority < 1 || priority > 5) {
      return res.status(400).json({
        error: '优先级无效',
        message: '优先级必须在1-5之间'
      });
    }

    // 创建愿望
    const result = await dbAsync.run(
      `INSERT INTO wishlists (couple_id, title, description, priority, target_date)
       VALUES (?, ?, ?, ?, ?)`,
      [coupleId, title, description, priority, target_date]
    );

    // 获取创建的愿望
    const wishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ?',
      [result.id]
    );

    res.status(201).json({
      message: '愿望创建成功',
      wishlist
    });
  } catch (error) {
    next(error);
  }
});

// 更新愿望
router.put('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const wishlistId = req.params.id;
    const { title, description, priority, target_date } = req.body;
    const coupleId = req.couple.id;

    // 检查愿望是否存在
    const existingWishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ? AND couple_id = ?',
      [wishlistId, coupleId]
    );

    if (!existingWishlist) {
      return res.status(404).json({
        error: '愿望不存在',
        message: '未找到指定的愿望项目'
      });
    }

    // 输入验证
    if (!title) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写愿望标题'
      });
    }

    if (priority && (priority < 1 || priority > 5)) {
      return res.status(400).json({
        error: '优先级无效',
        message: '优先级必须在1-5之间'
      });
    }

    // 更新愿望
    await dbAsync.run(
      `UPDATE wishlists SET title = ?, description = ?, priority = ?, target_date = ?
       WHERE id = ?`,
      [title, description, priority, target_date, wishlistId]
    );

    // 获取更新后的愿望
    const wishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ?',
      [wishlistId]
    );

    res.json({
      message: '愿望更新成功',
      wishlist
    });
  } catch (error) {
    next(error);
  }
});

// 标记愿望完成/未完成
router.patch('/:id/complete', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const wishlistId = req.params.id;
    const { is_completed } = req.body;
    const coupleId = req.couple.id;

    // 检查愿望是否存在
    const existingWishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ? AND couple_id = ?',
      [wishlistId, coupleId]
    );

    if (!existingWishlist) {
      return res.status(404).json({
        error: '愿望不存在',
        message: '未找到指定的愿望项目'
      });
    }

    const completedDate = is_completed ? new Date().toISOString().split('T')[0] : null;

    // 更新完成状态
    await dbAsync.run(
      'UPDATE wishlists SET is_completed = ?, completed_date = ? WHERE id = ?',
      [is_completed, completedDate, wishlistId]
    );

    // 获取更新后的愿望
    const wishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ?',
      [wishlistId]
    );

    res.json({
      message: is_completed ? '愿望标记为已完成' : '愿望标记为未完成',
      wishlist
    });
  } catch (error) {
    next(error);
  }
});

// 将愿望转换为约会记录
router.post('/:id/convert-to-record', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const wishlistId = req.params.id;
    const { record_date, location, rating, description: recordDescription, tags } = req.body;
    const coupleId = req.couple.id;
    const userId = req.user.id;

    // 检查愿望是否存在
    const wishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ? AND couple_id = ?',
      [wishlistId, coupleId]
    );

    if (!wishlist) {
      return res.status(404).json({
        error: '愿望不存在',
        message: '未找到指定的愿望项目'
      });
    }

    // 输入验证
    if (!record_date) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写约会日期'
      });
    }

    if (rating && (rating < 1 || rating > 5)) {
      return res.status(400).json({
        error: '评分无效',
        message: '评分必须在1-5之间'
      });
    }

    // 处理tags
    const tagsJson = tags && Array.isArray(tags) ? JSON.stringify(tags) : null;

    // 开始事务：创建约会记录并标记愿望为完成
    const description = recordDescription || wishlist.description;
    const title = wishlist.title;

    // 创建约会记录
    const recordResult = await dbAsync.run(
      `INSERT INTO records (couple_id, created_by, title, description, record_date, location, rating, tags)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [coupleId, userId, title, description, record_date, location, rating, tagsJson]
    );

    // 标记愿望为完成
    const completedDate = new Date().toISOString().split('T')[0];
    await dbAsync.run(
      'UPDATE wishlists SET is_completed = 1, completed_date = ? WHERE id = ?',
      [completedDate, wishlistId]
    );

    // 获取创建的约会记录
    const record = await dbAsync.get(
      `SELECT r.*, u.name as creator_name
       FROM records r
       LEFT JOIN users u ON r.created_by = u.id
       WHERE r.id = ?`,
      [recordResult.id]
    );

    // 获取更新后的愿望
    const updatedWishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ?',
      [wishlistId]
    );

    res.status(201).json({
      message: '愿望已转换为约会记录',
      record: {
        ...record,
        tags: record.tags ? JSON.parse(record.tags) : [],
        photos: []
      },
      wishlist: updatedWishlist
    });
  } catch (error) {
    next(error);
  }
});

// 删除愿望
router.delete('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const wishlistId = req.params.id;
    const coupleId = req.couple.id;

    // 检查愿望是否存在
    const existingWishlist = await dbAsync.get(
      'SELECT * FROM wishlists WHERE id = ? AND couple_id = ?',
      [wishlistId, coupleId]
    );

    if (!existingWishlist) {
      return res.status(404).json({
        error: '愿望不存在',
        message: '未找到指定的愿望项目'
      });
    }

    // 删除愿望
    await dbAsync.run('DELETE FROM wishlists WHERE id = ?', [wishlistId]);

    res.json({
      message: '愿望删除成功'
    });
  } catch (error) {
    next(error);
  }
});

// 批量操作愿望
router.post('/batch', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const { action, wishlist_ids } = req.body;
    const coupleId = req.couple.id;

    if (!action || !Array.isArray(wishlist_ids) || wishlist_ids.length === 0) {
      return res.status(400).json({
        error: '参数无效',
        message: '请提供有效的操作类型和愿望ID列表'
      });
    }

    // 验证所有愿望都属于当前情侣空间
    const placeholders = wishlist_ids.map(() => '?').join(',');
    const wishlists = await dbAsync.all(
      `SELECT id FROM wishlists WHERE id IN (${placeholders}) AND couple_id = ?`,
      [...wishlist_ids, coupleId]
    );

    if (wishlists.length !== wishlist_ids.length) {
      return res.status(400).json({
        error: '包含无效的愿望ID',
        message: '部分愿望不存在或不属于当前情侣空间'
      });
    }

    let result;
    switch (action) {
      case 'complete':
        const completedDate = new Date().toISOString().split('T')[0];
        result = await dbAsync.run(
          `UPDATE wishlists SET is_completed = 1, completed_date = ? 
           WHERE id IN (${placeholders})`,
          [completedDate, ...wishlist_ids]
        );
        break;

      case 'uncomplete':
        result = await dbAsync.run(
          `UPDATE wishlists SET is_completed = 0, completed_date = NULL 
           WHERE id IN (${placeholders})`,
          wishlist_ids
        );
        break;

      case 'delete':
        result = await dbAsync.run(
          `DELETE FROM wishlists WHERE id IN (${placeholders})`,
          wishlist_ids
        );
        break;

      default:
        return res.status(400).json({
          error: '无效操作',
          message: '支持的操作: complete, uncomplete, delete'
        });
    }

    res.json({
      message: `批量${action === 'complete' ? '完成' : action === 'uncomplete' ? '取消完成' : '删除'}成功`,
      affected_rows: result.changes
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;