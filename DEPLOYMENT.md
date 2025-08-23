# Love4Lili 部署指南

## 📋 部署前准备

### 环境要求
- Node.js 16+ 
- SQLite3
- 服务器支持文件上传（足够的磁盘空间）
- 域名和SSL证书（推荐）

## 🔧 配置环境变量

### 前端配置 (client/.env.production)
复制 `client/.env.example` 为 `client/.env.production` 并修改：

```bash
# 生产环境配置
# API服务器地址 - 修改为您的实际服务器地址
VITE_API_URL=https://your-domain.com/api

# 服务器基础URL（用于文件访问） - 修改为您的实际服务器地址  
VITE_SERVER_URL=https://your-domain.com

# 应用名称
VITE_APP_NAME=Love4Lili

# 环境标识
VITE_ENV=production
```

### 后端配置 (server/.env)
创建 `server/.env` 文件：

```bash
# 生产环境变量
NODE_ENV=production
PORT=3001

# 数据库配置（SQLite）
DB_PATH=./database.db

# JWT密钥 - 请生成一个强密码
JWT_SECRET=your-super-secret-jwt-key-here

# CORS允许的源
ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com

# 上传限制
MAX_FILE_SIZE=500MB
UPLOAD_PATH=./uploads

# VIP功能配置
FREE_STORAGE_LIMIT=1GB
VIP_STORAGE_LIMIT=10GB
```

## 🚀 部署步骤

### 1. 准备服务器
```bash
# 克隆代码
git clone <your-repo-url>
cd love4lili

# 安装依赖
cd server && npm install
cd ../client && npm install
```

### 2. 配置数据库
```bash
cd server
# 初始化数据库
node scripts/initDatabase.js

# 运行用户表更新脚本
node scripts/updateUserSchema.js

# 运行心情系统迁移
node scripts/migrateMoodSystem.js
```

### 3. 构建前端
```bash
cd client
npm run build
```

### 4. 配置Nginx（推荐）

创建 `/etc/nginx/sites-available/love4lili`：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /path/to/your/cert.crt;
    ssl_certificate_key /path/to/your/private.key;

    # 前端静态文件
    location / {
        root /path/to/love4lili/client/dist;
        try_files $uri $uri/ /index.html;
    }

    # API接口代理
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 上传文件大小限制
        client_max_body_size 500M;
    }

    # 上传文件访问
    location /uploads/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

### 5. 配置PM2（进程管理）

创建 `ecosystem.config.js`：

```javascript
module.exports = {
  apps: [{
    name: 'love4lili-server',
    script: './server/server.js',
    cwd: '/path/to/love4lili',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

启动服务：
```bash
# 安装PM2
npm install -g pm2

# 启动服务
pm2 start ecosystem.config.js

# 设置开机自启
pm2 startup
pm2 save
```

### 6. 配置域名解析
在您的域名服务商处，添加A记录：
- `your-domain.com` → 服务器IP
- `www.your-domain.com` → 服务器IP

### 7. SSL证书设置
使用Let's Encrypt免费证书：

```bash
# 安装certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 设置自动更新
sudo crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔒 安全配置

### 防火墙设置
```bash
# 只开放必要端口
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
```

### 定期备份
创建备份脚本 `backup.sh`：

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/path/to/backups"

# 备份数据库
cp /path/to/love4lili/server/database.db $BACKUP_DIR/database_$DATE.db

# 备份上传文件
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz /path/to/love4lili/server/uploads/

# 保留30天内的备份
find $BACKUP_DIR -name "*.db" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

设置定时备份：
```bash
crontab -e
# 添加：0 2 * * * /path/to/backup.sh
```

## 📊 监控和维护

### 日志查看
```bash
# PM2日志
pm2 logs love4lili-server

# Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 性能监控
```bash
# PM2监控
pm2 monit

# 系统资源
htop
df -h  # 磁盘使用
```

### 更新部署
```bash
# 拉取最新代码
git pull

# 重新构建前端
cd client && npm run build

# 重启服务
pm2 restart love4lili-server
```

## 🚨 故障排除

### 常见问题

1. **图片无法访问**
   - 检查uploads文件夹权限
   - 确认Nginx配置正确
   - 验证环境变量VITE_SERVER_URL设置

2. **API请求失败**
   - 检查CORS配置
   - 确认代理设置
   - 查看服务器日志

3. **数据库错误**
   - 检查database.db文件权限
   - 运行数据库更新脚本
   - 查看SQLite日志

### 性能优化

1. **启用CDN**
   - 将uploads文件夹配置到CDN
   - 修改VITE_SERVER_URL指向CDN

2. **数据库优化**
   - 定期清理日志
   - 添加数据库索引

3. **缓存配置**
   - Nginx静态文件缓存
   - 浏览器缓存策略

## 📞 技术支持

部署过程中如有问题，请检查：
1. 服务器日志 (`pm2 logs`)
2. Nginx错误日志
3. 浏览器开发者工具网络面板
4. 数据库连接状态

---

部署完成后，访问 `https://your-domain.com` 即可使用Love4Lili应用！💕