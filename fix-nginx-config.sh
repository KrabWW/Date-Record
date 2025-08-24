#!/bin/bash

# 修复Nginx配置错误的脚本
echo "🔧 修复Nginx配置文件..."

# 创建正确的Nginx配置
cat > /tmp/love4lili-nginx-config << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;

    # 设置最大上传文件大小
    client_max_body_size 500M;

    # 前端静态文件
    location / {
        root /var/www/love4lili/client/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # 静态文件缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1M;
            add_header Cache-Control "public, immutable";
        }
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
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
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
    gzip_types
        text/plain
        text/css
        application/json
        application/javascript
        text/xml
        application/xml
        application/xml+rss
        text/javascript
        application/x-font-ttf
        application/vnd.ms-fontobject
        font/opentype
        image/svg+xml
        image/x-icon;
}
EOF

echo "📝 配置文件已创建，内容预览："
head -20 /tmp/love4lili-nginx-config

echo ""
echo "💡 在服务器上运行以下命令修复："
echo ""
echo "# 1. 下载修复脚本"
echo "wget -O fix-nginx.sh https://pastebin.com/raw/YOUR_PASTE_ID || curl -o fix-nginx.sh https://pastebin.com/raw/YOUR_PASTE_ID"
echo ""
echo "# 2. 或者手动执行以下命令："
echo "sudo rm -f /etc/nginx/sites-enabled/love4lili"
echo "sudo tee /etc/nginx/sites-available/love4lili << 'NGINXEOF'"
cat /tmp/love4lili-nginx-config
echo "NGINXEOF"
echo ""
echo "# 3. 替换域名并启用配置"
echo 'sudo sed -i "s/DOMAIN_PLACEHOLDER/your-domain.com/g" /etc/nginx/sites-available/love4lili'
echo "sudo ln -sf /etc/nginx/sites-available/love4lili /etc/nginx/sites-enabled/"
echo "sudo nginx -t && sudo systemctl restart nginx"