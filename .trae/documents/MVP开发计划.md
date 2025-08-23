# Love4Lili MVP 开发计划

## 项目概述

情侣约会记录应用MVP版本，专注核心功能快速实现，后期可扩展为手机APP。

## 技术栈选择

### 后端
- **Node.js + Express** - 快速搭建RESTful API
- **SQLite** - 本地数据库，无需复杂配置
- **Multer** - 处理图片上传
- **bcrypt** - 密码加密
- **jsonwebtoken** - 用户认证

### 前端
- **React** - 组件化开发，后期可升级React Native
- **Tailwind CSS** - 快速样式开发，移动端友好
- **Axios** - HTTP请求库
- **React Router** - 页面路由

### 开发工具
- **Vite** - 前端构建工具
- **Nodemon** - 后端热重载
- **Concurrently** - 同时运行前后端

## MVP功能范围

### 核心功能（必须实现）
1. **用户认证**
   - 注册/登录
   - 创建情侣空间
   - 邀请码加入

2. **约会记录管理**
   - 添加约会记录
   - 查看记录列表
   - 编辑/删除记录
   - 上传照片

3. **愿望清单**
   - 添加愿望项目
   - 标记完成状态
   - 转换为约会记录

4. **基础展示**
   - 首页概览
   - 回忆相册
   - 基础设置

### 暂不实现（后续版本）
- 复杂数据统计
- 社交分享功能
- 高级UI动画
- 推送通知

## 项目结构

```
love4lili/
├── server/                 # 后端代码
│   ├── models/             # 数据模型
│   ├── routes/             # API路由
│   ├── middleware/         # 中间件
│   ├── uploads/            # 上传文件存储
│   ├── database.db         # SQLite数据库文件
│   └── server.js           # 服务器入口
├── client/                 # 前端代码
│   ├── src/
│   │   ├── components/     # React组件
│   │   ├── pages/          # 页面组件
│   │   ├── services/       # API调用
│   │   └── App.js          # 应用入口
│   └── public/
├── package.json            # 项目依赖
└── README.md              # 项目说明
```

## 开发阶段

### 阶段1: 项目初始化 (1-2天)
- [ ] 创建项目结构
- [ ] 安装依赖包
- [ ] 配置开发环境
- [ ] 设置SQLite数据库

### 阶段2: 后端API开发 (2-3天)
- [ ] 用户认证API
- [ ] 情侣空间管理API
- [ ] 约会记录CRUD API
- [ ] 愿望清单API
- [ ] 图片上传功能

### 阶段3: 前端页面开发 (2-3天)
- [ ] 登录/注册页面
- [ ] 首页布局
- [ ] 约会记录页面
- [ ] 愿望清单页面
- [ ] 基础导航组件

### 阶段4: 前后端集成 (1天)
- [ ] API接口调用
- [ ] 数据流测试
- [ ] 错误处理

### 阶段5: 测试优化 (1天)
- [ ] 功能完整性测试
- [ ] 移动端适配
- [ ] 性能优化

## 数据库设计

### 用户表 (users)
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  avatar_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 情侣空间表 (couples)
```sql
CREATE TABLE couples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user1_id INTEGER REFERENCES users(id),
  user2_id INTEGER REFERENCES users(id),
  couple_name VARCHAR(200) NOT NULL,
  invite_code VARCHAR(20) UNIQUE NOT NULL,
  anniversary_date DATE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 约会记录表 (records)
```sql
CREATE TABLE records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  couple_id INTEGER REFERENCES couples(id),
  created_by INTEGER REFERENCES users(id),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  record_date DATE NOT NULL,
  location VARCHAR(300),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  tags TEXT, -- JSON格式存储
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 愿望清单表 (wishlists)
```sql
CREATE TABLE wishlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  couple_id INTEGER REFERENCES couples(id),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 1,
  is_completed BOOLEAN DEFAULT FALSE,
  target_date DATE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 照片表 (photos)
```sql
CREATE TABLE photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  couple_id INTEGER REFERENCES couples(id),
  record_id INTEGER REFERENCES records(id),
  photo_url TEXT NOT NULL,
  caption TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## API接口设计

### 认证相关
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/logout` - 用户登出

### 情侣空间
- `POST /api/couples` - 创建情侣空间
- `POST /api/couples/join` - 通过邀请码加入
- `GET /api/couples/me` - 获取当前用户的情侣空间

### 约会记录
- `GET /api/records` - 获取记录列表
- `POST /api/records` - 创建记录
- `PUT /api/records/:id` - 更新记录
- `DELETE /api/records/:id` - 删除记录

### 愿望清单
- `GET /api/wishlists` - 获取愿望列表
- `POST /api/wishlists` - 创建愿望
- `PUT /api/wishlists/:id` - 更新愿望
- `DELETE /api/wishlists/:id` - 删除愿望

### 照片上传
- `POST /api/upload` - 上传照片

## 页面设计

### 路由规划
- `/` - 首页
- `/auth` - 登录/注册
- `/records` - 约会记录列表
- `/records/new` - 新建记录
- `/records/:id` - 记录详情
- `/wishlist` - 愿望清单
- `/gallery` - 相册
- `/settings` - 设置

### UI设计原则
1. **移动端优先** - 所有页面优先适配手机屏幕
2. **简洁明了** - MVP阶段以功能实现为主
3. **温馨风格** - 使用温暖的色彩搭配
4. **易于操作** - 大按钮，清晰的交互反馈

## 部署计划

### 开发阶段
- 本地运行：`npm run dev`
- 前端：localhost:3000
- 后端：localhost:5000

### 测试阶段
- 局域网访问，手机测试

### 上线阶段（可选）
- 简单云服务器部署
- 或直接打包PWA供本地使用

## 后续扩展计划

### 短期扩展
1. **PWA支持** - 添加到主屏幕功能
2. **UI美化** - 更精致的界面设计
3. **更多功能** - 数据统计、提醒功能

### 长期扩展
1. **React Native APP** - 真正的手机应用
2. **云端同步** - 数据云端存储
3. **高级功能** - AI推荐、智能提醒

## 开发时间预估

**总计：7-10天**
- 项目搭建：1-2天
- 后端开发：2-3天  
- 前端开发：2-3天
- 集成测试：1-2天

**每日开发时间：2-4小时**

## 成功标准

MVP版本完成标准：
1. 可以注册登录，创建情侣空间
2. 可以添加、查看、编辑约会记录
3. 可以管理愿望清单
4. 可以上传和查看照片
5. 手机端使用体验良好
6. 数据持久化存储

达到这个标准后，就可以给女朋友使用了！