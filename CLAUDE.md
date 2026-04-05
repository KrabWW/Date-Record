# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Love4Lili 是一个情侣约会记录与规划 Web 应用。用户可创建情侣空间、记录约会（含心情/情绪追踪）、管理愿望清单、上传照片/视频。项目语言以中文为主。

## 开发命令

```bash
# 安装所有依赖（根目录 + 前端 + 后端）
npm run setup

# 初始化 SQLite 数据库
npm run db:init

# 同时启动前后端开发服务器
npm run dev

# 构建前端生产版本
npm run build

# 启动生产服务器
npm start

# 仅后端（在 server/ 目录下）
cd server && npm run dev          # nodemon 热重载
cd server && npm run init-db      # 重新初始化数据库
cd server && npm run check-ffmpeg # 检查 FFmpeg（视频处理依赖）

# 仅前端（在 client/ 目录下）
cd client && npm run dev   # Vite 开发服务器
cd client && npm run build # 生产构建
cd client && npm run lint  # ESLint 检查
```

## 架构

### Monorepo 结构

- **`client/`** — React 18 单页应用（Vite + Tailwind CSS + React Router v6）
- **`server/`** — Express REST API（CommonJS 模块）
- **`IOS/`** — SwiftUI 开发规划文档（暂无代码）
- **`deploy-to-server.sh`** — Ubuntu 部署脚本（Nginx + PM2 + FFmpeg）

### 开发服务器端口

- 前端：`http://localhost:5173`（Vite 开发服务器）
- 后端：`http://localhost:3001`（Express，通过 Vite 代理 `/api` 和 `/uploads`）
- 后端默认 PORT 环境变量：`8888`

### 后端（server/）

入口文件：`server/server.js`。通过 `.env` 配置（PORT、JWT_SECRET、NODE_ENV、ALLOWED_ORIGINS）。

**中间件链：** helmet → CORS → 限流器 → JSON 解析（10mb 限制）→ 静态文件 → 路由 → 404 处理 → 错误处理。

**API 路由**（均挂载在 `/api` 下）：
- `/api/auth` — 注册、登录（JWT 认证）
- `/api/couples` — 创建/加入情侣空间（基于邀请码）
- `/api/records` — 约会记录增删改查（心情、情绪标签、地点）
- `/api/wishlists` — 愿望清单增删改查（优先级 1-5）
- `/api/upload` — 照片/视频上传（multer + FFmpeg 生成视频缩略图）

**数据库：** SQLite（`server/database.db`），建表脚本在 `server/database.sql`。共 5 张表：users、couples、records、wishlists、media。外键使用 CASCADE/SET NULL 删除策略。

### 前端（client/）

入口文件：`client/src/main.jsx`。Vite 将 `/api` 和 `/uploads` 代理到后端。

**核心目录：**
- `src/pages/` — 路由级页面组件
- `src/components/` — 可复用 UI 组件
- `src/services/` — Axios API 服务层
- `src/context/` — React Context（认证状态管理）
- `src/hooks/` — 自定义 React Hooks
- `src/styles/` — Tailwind 之外的额外样式

**构建：** Vite 输出到 `client/dist/`。生产环境下 Express 直接托管 `client/dist/` 静态文件，非 API 路由回退到 `index.html` 实现 SPA 路由。

### 认证机制

基于 JWT。认证中间件在 `server/middleware/` 中校验 token。前端通过服务层在 Axios 请求中携带 token。

### 文件上传

照片和视频存储在 `server/uploads/`。视频处理依赖系统安装的 FFmpeg（非 npm 包，已替换 ffmpeg-static）。`deploy-to-server.sh` 脚本会在服务器上安装 FFmpeg。

## Flutter App Bug Hunting（自动化 Bug 发现）

```bash
cd flutter_app

# 运行所有 Maestro flow，自动收集 bug 证据
./scripts/bug_hunt.sh

# 只跑指定 flow
./scripts/bug_hunt.sh --flow=02

# 跳过成功截图（更快）
./scripts/bug_hunt.sh --skip-pass
```

Bug 证据输出到 `flutter_app/bug_reports/YYYY-MM-DD/`，包含截图、logcat 和描述。
设计文档：`docs/superpowers/specs/2026-04-05-bug-hunting-design.md`

## Flutter App 集成测试（Patrol — 已弃用）

### 启动模拟器

```bash
# 列出可用的 AVD
$HOME/Library/Android/sdk/emulator/emulator -list-avds

# 启动模拟器（后台运行）
$HOME/Library/Android/sdk/emulator/emulator -avd <avd_name> -no-snapshot-load &

# 确认模拟器在线
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:$HOME/.pub-cache/bin"
adb devices
# 应该看到 emulator-5554    device
```

### 运行测试

**重要：每次改代码后必须先 `flutter clean`，否则增量构建会用缓存的旧 APK。**

```bash
cd flutter_app
flutter clean

# 各模块测试命令
patrol test integration_test/auth_flow_test.dart -d emulator-5554       # 认证
patrol test integration_test/couple_setup_test.dart -d emulator-5554   # 情侣设置
patrol test integration_test/records_test.dart -d emulator-5554        # 约会记录
patrol test integration_test/wishlist_test.dart -d emulator-5554       # 愿望清单
patrol test integration_test/gallery_test.dart -d emulator-5554        # 相册
```

### 注意事项

- **无需启动本地后端** — Flutter app 直接访问公网服务器 `http://8.140.227.83/api`
- **flutter clean 每次必做** — patrol 的构建系统不会自动检测 integration test 文件的变更，不 clean 会用旧缓存导致测试失败
- 全量构建约 2-5 分钟，增量构建约 30 秒（但增量可能不可靠）
