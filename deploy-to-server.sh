#!/bin/bash
set -e

# 部署配置
SERVER_IP="your-server-ip"  # 替换为你的服务器IP
SERVER_USER="ubuntu"        # 替换为你的服务器用户名
SERVER_PATH="/var/www/love4lili"
DOMAIN="your-domain.com"    # 替换为你的域名，或使用服务器IP

echo "🚀 开始部署Love4Lili到Ubuntu服务器..."

# 创建临时部署目录
TEMP_DIR="/tmp/love4lili-deploy"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

echo "📦 准备部署文件..."

# 复制项目文件（排除node_modules）
rsync -av --exclude='node_modules' --exclude='.git' --exclude='server/uploads' --exclude='server/database.db' ./ $TEMP_DIR/

# 创建部署脚本
cat > $TEMP_DIR/server-setup.sh << 'EOF'
#!/bin/bash
set -e

echo "🔧 安装系统依赖..."
sudo apt update
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs nginx ffmpeg
sudo npm install -g pm2

# 验证FFmpeg安装
echo "📹 验证FFmpeg安装..."
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg 已安装: $(ffmpeg -version | head -1)"
else
    echo "❌ FFmpeg 安装失败"
    exit 1
fi

echo "📁 设置项目目录..."
sudo mkdir -p /var/www/love4lili
sudo chown -R $USER:$USER /var/www/love4lili

cd /var/www/love4lili

echo "📦 安装项目依赖..."
npm install
cd server && npm install
cd ../client && npm install

echo "⚙️ 配置环境变量..."
# 后端环境变量
cat > server/.env << 'ENVEOF'
NODE_ENV=production
PORT=3001
DB_PATH=./database.db
JWT_SECRET=love4lili-super-secret-jwt-key-change-this-in-production
ALLOWED_ORIGINS=http://DOMAIN_PLACEHOLDER,https://DOMAIN_PLACEHOLDER
MAX_FILE_SIZE=500MB
UPLOAD_PATH=./uploads
FREE_STORAGE_LIMIT=1GB
VIP_STORAGE_LIMIT=10GB
ENVEOF

# 前端环境变量
cat > client/.env.production << 'ENVEOF'
VITE_API_URL=http://DOMAIN_PLACEHOLDER/api
VITE_SERVER_URL=http://DOMAIN_PLACEHOLDER
VITE_APP_NAME=Love4Lili
VITE_ENV=production
ENVEOF

# 替换域名占位符
sed -i "s/DOMAIN_PLACEHOLDER/$1/g" server/.env
sed -i "s/DOMAIN_PLACEHOLDER/$1/g" client/.env.production

echo "🗄️ 初始化数据库..."
cd server
node scripts/initDatabase.js
node scripts/updateUserSchema.js
node scripts/migrateMoodSystem.js

echo "🏗️ 构建前端..."
cd ../client
npm run build

echo "🌐 配置Nginx..."
sudo tee /etc/nginx/sites-available/love4lili << 'NGINXEOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;

    # 前端静态文件
    location / {
        root /var/www/love4lili/client/dist;
        index index.html;
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
NGINXEOF

# 替换Nginx配置中的域名
sudo sed -i "s/DOMAIN_PLACEHOLDER/$1/g" /etc/nginx/sites-available/love4lili

# 启用站点
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/love4lili /etc/nginx/sites-enabled/

# 测试Nginx配置
sudo nginx -t && sudo systemctl restart nginx

echo "🔄 配置PM2..."
cd /var/www/love4lili

cat > ecosystem.config.js << 'PM2EOF'
module.exports = {
  apps: [{
    name: 'love4lili-server',
    script: './server/server.js',
    cwd: '/var/www/love4lili',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
};
PM2EOF

# 启动服务
pm2 start ecosystem.config.js
pm2 startup
pm2 save

echo "🔒 配置防火墙..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

echo "✅ 部署完成！"
echo "🌐 访问地址: http://$1"
echo "📊 服务监控: pm2 monit"
echo "📝 查看日志: pm2 logs love4lili-server"
EOF

chmod +x $TEMP_DIR/server-setup.sh

echo "📤 上传文件到服务器..."
# 上传项目文件
scp -r $TEMP_DIR/* $SERVER_USER@$SERVER_IP:/tmp/

echo "🔧 在服务器上执行安装..."
ssh $SERVER_USER@$SERVER_IP << REMOTE_SCRIPT
    # 复制项目到目标目录
    sudo mkdir -p $SERVER_PATH
    sudo cp -r /tmp/* $SERVER_PATH/
    sudo chown -R $USER:$USER $SERVER_PATH
    
    # 执行服务器设置脚本
    cd $SERVER_PATH
    chmod +x server-setup.sh
    ./server-setup.sh $DOMAIN
    
    # 清理临时文件
    rm -rf /tmp/love4lili-deploy /tmp/server-setup.sh
REMOTE_SCRIPT

echo "🎉 部署完成！"
echo "🌐 访问: http://$DOMAIN"
echo ""
echo "📊 服务器管理命令："
echo "  检查服务状态: ssh $SERVER_USER@$SERVER_IP 'pm2 status'"
echo "  查看日志: ssh $SERVER_USER@$SERVER_IP 'pm2 logs love4lili-server'"
echo "  重启服务: ssh $SERVER_USER@$SERVER_IP 'pm2 restart love4lili-server'"

# 清理本地临时文件
rm -rf $TEMP_DIR