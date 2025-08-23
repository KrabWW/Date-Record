const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// 数据库路径
const dbPath = path.join(__dirname, '..', 'database.db');

// 评分到心情的映射
const ratingToMoodMap = {
  5: 'amazing',
  4: 'happy', 
  3: 'good',
  2: 'okay',
  1: 'meh'
};

function migrateMoodSystem() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error connecting to database:', err);
        reject(err);
        return;
      }
      console.log('Connected to database for migration');
    });

    db.serialize(() => {
      // 1. 添加新字段
      console.log('Adding new mood and emotion_tags columns...');
      
      db.run(`ALTER TABLE records ADD COLUMN mood VARCHAR(20) DEFAULT 'good'`, (err) => {
        if (err && !err.message.includes('duplicate column name')) {
          console.error('Error adding mood column:', err);
          reject(err);
          return;
        }
      });

      db.run(`ALTER TABLE records ADD COLUMN emotion_tags TEXT`, (err) => {
        if (err && !err.message.includes('duplicate column name')) {
          console.error('Error adding emotion_tags column:', err);
          reject(err);
          return;
        }
      });

      // 2. 迁移现有数据：将rating转换为mood
      console.log('Migrating rating data to mood system...');
      
      db.all(`SELECT id, rating FROM records WHERE rating IS NOT NULL`, (err, rows) => {
        if (err) {
          console.error('Error reading records:', err);
          reject(err);
          return;
        }

        if (rows.length === 0) {
          console.log('No existing ratings to migrate');
          finalizeMigration();
          return;
        }

        console.log(`Found ${rows.length} records with ratings to migrate`);

        let completed = 0;
        
        rows.forEach((row) => {
          const mood = ratingToMoodMap[row.rating] || 'good';
          
          db.run(
            `UPDATE records SET mood = ? WHERE id = ?`,
            [mood, row.id],
            (err) => {
              if (err) {
                console.error(`Error updating record ${row.id}:`, err);
                reject(err);
                return;
              }
              
              completed++;
              console.log(`Migrated record ${row.id}: rating ${row.rating} -> mood ${mood}`);
              
              if (completed === rows.length) {
                finalizeMigration();
              }
            }
          );
        });
      });

      function finalizeMigration() {
        // 3. 添加约束和索引
        console.log('Adding constraints and indexes...');
        
        // 由于SQLite的限制，我们不能直接添加CHECK约束到现有列
        // 但新的数据插入会使用正确的约束（在database.sql中定义）
        
        // 添加索引优化查询
        db.run(`CREATE INDEX IF NOT EXISTS idx_records_mood ON records(mood)`, (err) => {
          if (err) {
            console.error('Error creating mood index:', err);
          } else {
            console.log('Created mood index');
          }
        });

        // 4. 验证迁移结果
        console.log('Verifying migration...');
        
        db.all(`
          SELECT 
            mood, 
            COUNT(*) as count,
            AVG(CASE WHEN rating IS NOT NULL THEN rating END) as avg_original_rating
          FROM records 
          GROUP BY mood
        `, (err, results) => {
          if (err) {
            console.error('Error verifying migration:', err);
            reject(err);
            return;
          }

          console.log('\nMigration Results:');
          console.log('==================');
          results.forEach(row => {
            console.log(`Mood: ${row.mood}, Count: ${row.count}, Avg Original Rating: ${row.avg_original_rating || 'N/A'}`);
          });

          console.log('\n✅ Migration completed successfully!');
          console.log('\nNext steps:');
          console.log('1. Update your API endpoints to use mood instead of rating');
          console.log('2. Update frontend components to use MoodSelector');
          console.log('3. Test the new mood system thoroughly');
          console.log('4. Consider removing the rating column after testing (optional)');
          
          db.close((err) => {
            if (err) {
              console.error('Error closing database:', err);
              reject(err);
            } else {
              console.log('Database connection closed');
              resolve();
            }
          });
        });
      }
    });
  });
}

// 如果直接运行此脚本
if (require.main === module) {
  console.log('🔄 Starting mood system migration...');
  console.log('This will convert existing rating data to the new mood system');
  console.log('==========================================\n');

  migrateMoodSystem()
    .then(() => {
      console.log('\n🎉 Migration completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateMoodSystem, ratingToMoodMap };