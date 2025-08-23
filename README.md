# Love4Lili - 情侣约会记录应用

一个专为情侣设计的约会记录与规划应用，帮助情侣记录美好回忆、规划未来约会。

## 功能特性

- 👫 情侣空间管理
- 📝 约会记录增删改查
- 💭 愿望清单管理
- 📸 照片上传和展示
- 📱 移动端优先设计
- 🔒 私密安全的数据存储

## 技术栈

- **前端**: React 18 + Vite + Tailwind CSS
- **后端**: Node.js + Express
- **数据库**: SQLite
- **认证**: JWT

## 快速开始

### 环境要求

- Node.js 16+
- npm 或 yarn

### 安装依赖

```bash
# 安装所有依赖（根目录、前端、后端）
npm run setup
```

### 初始化数据库

```bash
# 创建数据库表
npm run db:init
```

### 启动开发服务器

```bash
# 同时启动前后端开发服务器
npm run dev
```

- 前端: http://localhost:5173
- 后端: http://localhost:5000

### 生产构建

```bash
# 构建前端
npm run build

# 启动生产服务器
npm start
```

## 项目结构

```
love4lili/
├── client/                 # React 前端
│   ├── src/
│   │   ├── components/     # 可复用组件
│   │   ├── pages/          # 页面组件
│   │   ├── services/       # API 服务
│   │   ├── context/        # React Context
│   │   └── App.jsx
│   ├── public/
│   └── package.json
├── server/                 # Node.js 后端
│   ├── routes/             # API 路由
│   ├── models/             # 数据模型
│   ├── middleware/         # 中间件
│   ├── scripts/            # 工具脚本
│   ├── uploads/            # 文件上传目录
│   └── server.js
├── .trae/                  # 项目文档
└── package.json
```

## API 接口

### 认证
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录

### 情侣空间
- `POST /api/couples` - 创建情侣空间
- `POST /api/couples/join` - 加入情侣空间
- `GET /api/couples/me` - 获取当前情侣空间

### 约会记录
- `GET /api/records` - 获取记录列表
- `POST /api/records` - 创建记录
- `PUT /api/records/:id` - 更新记录
- `DELETE /api/records/:id` - 删除记录

### 愿望清单
- `GET /api/wishlists` - 获取愿望列表
- `POST /api/wishlists` - 创建愿望
- `PUT /api/wishlists/:id` - 更新愿望

## 开发说明

这是一个MVP版本，专注于核心功能的快速实现。后续可以扩展为：

1. PWA应用 - 可安装到手机主屏幕
2. React Native应用 - 真正的手机APP
3. 云端同步 - 数据云存储

## 许可证

MIT License