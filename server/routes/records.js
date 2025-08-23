const express = require('express');
const { dbAsync } = require('../models/database');
const { authenticateToken, validateCoupleAccess } = require('../middleware/auth');

const router = express.Router();

// 获取约会记录列表
router.get('/', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const coupleId = req.couple.id;
    const { page = 1, limit = 10, sort = 'date_desc' } = req.query;

    // 计算偏移量
    const offset = (page - 1) * limit;

    // 确定排序方式
    let orderBy = 'record_date DESC, created_at DESC';
    switch (sort) {
      case 'date_asc':
        orderBy = 'record_date ASC, created_at ASC';
        break;
      case 'created_desc':
        orderBy = 'created_at DESC';
        break;
      case 'created_asc':
        orderBy = 'created_at ASC';
        break;
      case 'rating_desc':
        orderBy = 'rating DESC, record_date DESC';
        break;
    }

    // 获取记录列表
    const records = await dbAsync.all(
      `SELECT r.*, u.name as creator_name,
              COUNT(p.id) as photo_count
       FROM records r
       LEFT JOIN users u ON r.created_by = u.id
       LEFT JOIN photos p ON r.id = p.record_id
       WHERE r.couple_id = ?
       GROUP BY r.id
       ORDER BY ${orderBy}
       LIMIT ? OFFSET ?`,
      [coupleId, parseInt(limit), offset]
    );

    // 获取总记录数
    const totalResult = await dbAsync.get(
      'SELECT COUNT(*) as total FROM records WHERE couple_id = ?',
      [coupleId]
    );

    // 处理tags和emotion_tags字段（将JSON字符串解析为数组）
    const processedRecords = records.map(record => ({
      ...record,
      tags: record.tags ? JSON.parse(record.tags) : [],
      emotion_tags: record.emotion_tags ? JSON.parse(record.emotion_tags) : [],
      photo_count: parseInt(record.photo_count) || 0
    }));

    res.json({
      records: processedRecords,
      pagination: {
        current_page: parseInt(page),
        total_pages: Math.ceil(totalResult.total / limit),
        total_records: totalResult.total,
        has_next: offset + records.length < totalResult.total,
        has_prev: page > 1
      }
    });
  } catch (error) {
    next(error);
  }
});

// 获取单个约会记录详情
router.get('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const recordId = req.params.id;
    const coupleId = req.couple.id;

    // 获取记录详情
    const record = await dbAsync.get(
      `SELECT r.*, u.name as creator_name
       FROM records r
       LEFT JOIN users u ON r.created_by = u.id
       WHERE r.id = ? AND r.couple_id = ?`,
      [recordId, coupleId]
    );

    if (!record) {
      return res.status(404).json({
        error: '记录不存在',
        message: '未找到指定的约会记录'
      });
    }

    // 获取相关照片
    const photos = await dbAsync.all(
      'SELECT * FROM photos WHERE record_id = ? ORDER BY created_at',
      [recordId]
    );

    // 处理数据
    const processedRecord = {
      ...record,
      tags: record.tags ? JSON.parse(record.tags) : [],
      emotion_tags: record.emotion_tags ? JSON.parse(record.emotion_tags) : [],
      photos
    };

    res.json({
      record: processedRecord
    });
  } catch (error) {
    next(error);
  }
});

// 创建约会记录
router.post('/', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const { title, description, record_date, location, mood, emotion_tags, rating, tags } = req.body;
    const coupleId = req.couple.id;
    const userId = req.user.id;

    // 输入验证
    if (!title || !record_date) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写约会标题和日期'
      });
    }

    // 验证心情值
    if (mood && !['amazing', 'happy', 'good', 'okay', 'meh'].includes(mood)) {
      return res.status(400).json({
        error: '心情值无效',
        message: '心情必须是：amazing, happy, good, okay, meh 中的一种'
      });
    }

    // 兼容性：如果传了rating，转换为mood
    let finalMood = mood || 'good';
    if (rating && !mood) {
      const ratingToMoodMap = { 5: 'amazing', 4: 'happy', 3: 'good', 2: 'okay', 1: 'meh' };
      finalMood = ratingToMoodMap[rating] || 'good';
    }

    // 处理tags和emotion_tags
    const tagsJson = tags && Array.isArray(tags) ? JSON.stringify(tags) : null;
    const emotionTagsJson = emotion_tags && Array.isArray(emotion_tags) ? JSON.stringify(emotion_tags) : null;

    // 创建记录
    const result = await dbAsync.run(
      `INSERT INTO records (couple_id, created_by, title, description, record_date, location, mood, emotion_tags, tags)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [coupleId, userId, title, description, record_date, location, finalMood, emotionTagsJson, tagsJson]
    );

    // 获取创建的记录
    const record = await dbAsync.get(
      `SELECT r.*, u.name as creator_name
       FROM records r
       LEFT JOIN users u ON r.created_by = u.id
       WHERE r.id = ?`,
      [result.id]
    );

    // 处理返回数据
    const processedRecord = {
      ...record,
      tags: record.tags ? JSON.parse(record.tags) : [],
      emotion_tags: record.emotion_tags ? JSON.parse(record.emotion_tags) : [],
      photos: []
    };

    res.status(201).json({
      message: '约会记录创建成功',
      record: processedRecord
    });
  } catch (error) {
    next(error);
  }
});

// 更新约会记录
router.put('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const recordId = req.params.id;
    const { title, description, record_date, location, mood, emotion_tags, rating, tags } = req.body;
    const coupleId = req.couple.id;

    // 检查记录是否存在
    const existingRecord = await dbAsync.get(
      'SELECT * FROM records WHERE id = ? AND couple_id = ?',
      [recordId, coupleId]
    );

    if (!existingRecord) {
      return res.status(404).json({
        error: '记录不存在',
        message: '未找到指定的约会记录'
      });
    }

    // 输入验证
    if (!title || !record_date) {
      return res.status(400).json({
        error: '缺少必要信息',
        message: '请填写约会标题和日期'
      });
    }

    // 验证心情值
    if (mood && !['amazing', 'happy', 'good', 'okay', 'meh'].includes(mood)) {
      return res.status(400).json({
        error: '心情值无效',
        message: '心情必须是：amazing, happy, good, okay, meh 中的一种'
      });
    }

    // 兼容性：如果传了rating，转换为mood
    let finalMood = mood || existingRecord.mood || 'good';
    if (rating && !mood) {
      const ratingToMoodMap = { 5: 'amazing', 4: 'happy', 3: 'good', 2: 'okay', 1: 'meh' };
      finalMood = ratingToMoodMap[rating] || 'good';
    }

    // 处理tags和emotion_tags
    const tagsJson = tags && Array.isArray(tags) ? JSON.stringify(tags) : null;
    const emotionTagsJson = emotion_tags && Array.isArray(emotion_tags) ? JSON.stringify(emotion_tags) : null;

    // 更新记录
    await dbAsync.run(
      `UPDATE records SET title = ?, description = ?, record_date = ?, location = ?, 
       mood = ?, emotion_tags = ?, tags = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [title, description, record_date, location, finalMood, emotionTagsJson, tagsJson, recordId]
    );

    // 获取更新后的记录
    const record = await dbAsync.get(
      `SELECT r.*, u.name as creator_name
       FROM records r
       LEFT JOIN users u ON r.created_by = u.id
       WHERE r.id = ?`,
      [recordId]
    );

    // 获取相关照片
    const photos = await dbAsync.all(
      'SELECT * FROM photos WHERE record_id = ? ORDER BY created_at',
      [recordId]
    );

    // 处理返回数据
    const processedRecord = {
      ...record,
      tags: record.tags ? JSON.parse(record.tags) : [],
      emotion_tags: record.emotion_tags ? JSON.parse(record.emotion_tags) : [],
      photos
    };

    res.json({
      message: '约会记录更新成功',
      record: processedRecord
    });
  } catch (error) {
    next(error);
  }
});

// 删除约会记录
router.delete('/:id', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const recordId = req.params.id;
    const coupleId = req.couple.id;

    // 检查记录是否存在
    const existingRecord = await dbAsync.get(
      'SELECT * FROM records WHERE id = ? AND couple_id = ?',
      [recordId, coupleId]
    );

    if (!existingRecord) {
      return res.status(404).json({
        error: '记录不存在',
        message: '未找到指定的约会记录'
      });
    }

    // 删除相关照片记录（文件删除在photos路由中处理）
    await dbAsync.run('DELETE FROM photos WHERE record_id = ?', [recordId]);

    // 删除约会记录
    await dbAsync.run('DELETE FROM records WHERE id = ?', [recordId]);

    res.json({
      message: '约会记录删除成功'
    });
  } catch (error) {
    next(error);
  }
});

// 获取记录统计信息
router.get('/stats/summary', authenticateToken, validateCoupleAccess, async (req, res, next) => {
  try {
    const coupleId = req.couple.id;

    // 基础统计
    const totalRecords = await dbAsync.get(
      'SELECT COUNT(*) as total FROM records WHERE couple_id = ?',
      [coupleId]
    );

    // 心情分布统计
    const moodStats = await dbAsync.all(
      `SELECT mood, COUNT(*) as count
       FROM records
       WHERE couple_id = ?
       GROUP BY mood
       ORDER BY count DESC`,
      [coupleId]
    );

    const recentRecords = await dbAsync.get(
      'SELECT COUNT(*) as recent FROM records WHERE couple_id = ? AND record_date >= date("now", "-30 days")',
      [coupleId]
    );

    // 按月统计
    const monthlyStats = await dbAsync.all(
      `SELECT strftime('%Y-%m', record_date) as month, COUNT(*) as count
       FROM records
       WHERE couple_id = ?
       GROUP BY strftime('%Y-%m', record_date)
       ORDER BY month DESC
       LIMIT 6`,
      [coupleId]
    );

    // 情感标签统计
    const emotionTagsStats = await dbAsync.all(
      `SELECT emotion_tags
       FROM records
       WHERE couple_id = ? AND emotion_tags IS NOT NULL AND emotion_tags != ''`,
      [coupleId]
    );

    // 解析和统计情感标签
    const emotionTagsCounts = {};
    emotionTagsStats.forEach(record => {
      try {
        const tags = JSON.parse(record.emotion_tags);
        tags.forEach(tag => {
          emotionTagsCounts[tag] = (emotionTagsCounts[tag] || 0) + 1;
        });
      } catch (e) {
        // 忽略解析错误
      }
    });

    const topEmotionTags = Object.entries(emotionTagsCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5)
      .map(([tag, count]) => ({ tag, count }));

    res.json({
      total_records: totalRecords.total,
      recent_records: recentRecords.recent,
      monthly_stats: monthlyStats,
      mood_distribution: moodStats,
      top_emotion_tags: topEmotionTags
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;