const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'database.db');
const sqlPath = path.join(__dirname, '..', 'database.sql');

// 创建数据库连接
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('连接数据库失败:', err.message);
    return;
  }
  console.log('已连接到 SQLite 数据库');
});

// 读取并执行SQL脚本
fs.readFile(sqlPath, 'utf8', (err, data) => {
  if (err) {
    console.error('读取SQL文件失败:', err);
    return;
  }

  // 执行SQL脚本
  db.exec(data, (err) => {
    if (err) {
      console.error('数据库初始化失败:', err);
    } else {
      console.log('数据库初始化成功');
      
      // 可选：插入一些测试数据
      insertTestData();
    }
    
    // 关闭数据库连接
    db.close((err) => {
      if (err) {
        console.error('关闭数据库连接失败:', err.message);
      } else {
        console.log('数据库连接已关闭');
      }
    });
  });
});

// 插入测试数据（可选）
function insertTestData() {
  console.log('正在插入测试数据...');
  
  // 这里可以插入一些测试数据，方便开发调试
  const testSQL = `
    INSERT OR IGNORE INTO users (email, password_hash, name) VALUES 
    ('test1@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'TestUser1'),
    ('test2@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'TestUser2');
  `;
  
  db.exec(testSQL, (err) => {
    if (err) {
      console.error('插入测试数据失败:', err);
    } else {
      console.log('测试数据插入成功');
    }
  });
}