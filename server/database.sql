-- Love4Lili 数据库初始化脚本

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    is_vip BOOLEAN DEFAULT FALSE,
    used_storage INTEGER DEFAULT 0,
    vip_expires_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 情侣空间表
CREATE TABLE IF NOT EXISTS couples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user1_id INTEGER NOT NULL,
    user2_id INTEGER,
    couple_name VARCHAR(200) NOT NULL,
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    anniversary_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 约会记录表
CREATE TABLE IF NOT EXISTS records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    couple_id INTEGER NOT NULL,
    created_by INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    record_date DATE NOT NULL,
    location VARCHAR(300),
    mood VARCHAR(20) DEFAULT 'good' CHECK (mood IN ('amazing', 'happy', 'good', 'okay', 'meh')),
    emotion_tags TEXT, -- JSON格式: ["romantic", "fun", "peaceful"]
    tags TEXT, -- JSON格式: ["浪漫", "海边"] - 保留原有标签系统用于其他用途
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (couple_id) REFERENCES couples(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- 愿望清单表
CREATE TABLE IF NOT EXISTS wishlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    couple_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority INTEGER DEFAULT 1 CHECK (priority >= 1 AND priority <= 5),
    is_completed BOOLEAN DEFAULT FALSE,
    target_date DATE,
    completed_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (couple_id) REFERENCES couples(id) ON DELETE CASCADE
);

-- 媒体文件表 (照片和视频)
CREATE TABLE IF NOT EXISTS media (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    couple_id INTEGER NOT NULL,
    record_id INTEGER,
    file_url TEXT NOT NULL,
    file_type VARCHAR(20) NOT NULL CHECK (file_type IN ('photo', 'video')),
    caption TEXT,
    file_size INTEGER,
    mime_type VARCHAR(50),
    duration INTEGER, -- 视频时长（秒），照片为NULL
    thumbnail_url TEXT, -- 视频缩略图URL，照片可为空
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (couple_id) REFERENCES couples(id) ON DELETE CASCADE,
    FOREIGN KEY (record_id) REFERENCES records(id) ON DELETE SET NULL
);

-- 创建索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_couples_users ON couples(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_records_couple ON records(couple_id);
CREATE INDEX IF NOT EXISTS idx_records_date ON records(record_date DESC);
CREATE INDEX IF NOT EXISTS idx_wishlists_couple ON wishlists(couple_id);
CREATE INDEX IF NOT EXISTS idx_media_couple ON media(couple_id);
CREATE INDEX IF NOT EXISTS idx_media_record ON media(record_id);
CREATE INDEX IF NOT EXISTS idx_media_type ON media(file_type);