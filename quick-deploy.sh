#!/bin/bash

# 简化版一键部署脚本
echo "🚀 Love4Lili 一键部署工具"
echo ""

# 检查必要工具
if ! command -v ssh &> /dev/null; then
    echo "❌ 需要安装 SSH 客户端"
    exit 1
fi

if ! command -v scp &> /dev/null; then
    echo "❌ 需要安装 SCP 工具"
    exit 1
fi

# 获取用户输入
read -p "🌐 请输入服务器IP地址: " SERVER_IP
read -p "👤 请输入服务器用户名 [ubuntu]: " SERVER_USER
SERVER_USER=${SERVER_USER:-ubuntu}
read -p "🏠 请输入域名或服务器IP [$SERVER_IP]: " DOMAIN
DOMAIN=${DOMAIN:-$SERVER_IP}

echo ""
echo "📋 部署配置："
echo "  服务器: $SERVER_USER@$SERVER_IP"
echo "  域名: $DOMAIN"
echo ""

read -p "❓ 确认开始部署? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ 部署已取消"
    exit 1
fi

# 修改部署脚本中的变量
sed -i '' "s/your-server-ip/$SERVER_IP/g" deploy-to-server.sh
sed -i '' "s/ubuntu/$SERVER_USER/g" deploy-to-server.sh
sed -i '' "s/your-domain.com/$DOMAIN/g" deploy-to-server.sh

# 执行部署
chmod +x deploy-to-server.sh
./deploy-to-server.sh

echo ""
echo "🎉 部署完成！请访问 http://$DOMAIN 查看应用"