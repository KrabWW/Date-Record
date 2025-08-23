const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// 数据库路径
const dbPath = path.join(__dirname, '..', 'database.db');

function updateUserSchema() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error connecting to database:', err);
        reject(err);
        return;
      }
      console.log('Connected to database for schema update');
    });

    db.serialize(() => {
      console.log('Updating users table schema...');
      
      // 添加缺失的字段
      const fieldsToAdd = [
        { name: 'is_vip', type: 'BOOLEAN DEFAULT FALSE' },
        { name: 'used_storage', type: 'INTEGER DEFAULT 0' },
        { name: 'vip_expires_at', type: 'DATETIME' }
      ];

      let completed = 0;
      const total = fieldsToAdd.length;

      fieldsToAdd.forEach((field, index) => {
        db.run(`ALTER TABLE users ADD COLUMN ${field.name} ${field.type}`, (err) => {
          if (err && !err.message.includes('duplicate column name')) {
            console.error(`Error adding column ${field.name}:`, err);
            reject(err);
            return;
          }
          
          if (err && err.message.includes('duplicate column name')) {
            console.log(`Column ${field.name} already exists, skipping...`);
          } else {
            console.log(`✅ Added column: ${field.name} ${field.type}`);
          }
          
          completed++;
          if (completed === total) {
            verifySchema(db, resolve, reject);
          }
        });
      });
    });
  });
}

function verifySchema(db, resolve, reject) {
  console.log('\nVerifying updated schema...');
  
  db.get("PRAGMA table_info(users)", (err, result) => {
    if (err) {
      console.error('Error verifying schema:', err);
      reject(err);
      return;
    }
    
    // 获取所有列信息
    db.all("PRAGMA table_info(users)", (err, columns) => {
      if (err) {
        console.error('Error getting column info:', err);
        reject(err);
        return;
      }
      
      console.log('\nCurrent users table schema:');
      console.log('============================');
      columns.forEach(col => {
        console.log(`${col.name}: ${col.type} ${col.notnull ? 'NOT NULL' : ''} ${col.dflt_value ? `DEFAULT ${col.dflt_value}` : ''}`);
      });
      
      // 检查必需的字段是否存在
      const requiredFields = ['is_vip', 'used_storage', 'vip_expires_at'];
      const existingFields = columns.map(col => col.name);
      const missingFields = requiredFields.filter(field => !existingFields.includes(field));
      
      if (missingFields.length > 0) {
        console.error('\n❌ Missing required fields:', missingFields);
        reject(new Error(`Missing fields: ${missingFields.join(', ')}`));
        return;
      }
      
      console.log('\n✅ Schema update completed successfully!');
      console.log('All required fields are present in the users table.');
      
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
  });
}

// 如果直接运行此脚本
if (require.main === module) {
  console.log('🔄 Starting users table schema update...');
  console.log('This will add missing VIP-related columns to the users table');
  console.log('==========================================\n');

  updateUserSchema()
    .then(() => {
      console.log('\n🎉 Schema update completed successfully!');
      console.log('\nNext steps:');
      console.log('1. Restart your server');
      console.log('2. Test the upload functionality');
      console.log('3. VIP features should now work properly');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Schema update failed:', error);
      process.exit(1);
    });
}

module.exports = { updateUserSchema };