# Ubuntu服务器npm install问题解决指南

## 问题描述
在Ubuntu服务器上运行`npm install`时，ffmpeg-static包安装超时，导致整个安装过程卡住。

## 解决方案

### 方案一：使用淘宝镜像源（推荐）

#### 1. 临时使用淘宝镜像
```bash
# 清理npm缓存
npm cache clean --force

# 使用淘宝镜像安装
npm install --registry=https://registry.npmmirror.com
```

#### 2. 永久配置淘宝镜像
```bash
# 设置npm镜像源
npm config set registry https://registry.npmmirror.com

# 验证配置
npm config get registry

# 安装依赖
npm install
```

### 方案二：增加超时时间配置

#### 1. 使用项目中的.npmrc配置
项目已经包含了`.npmrc`文件，包含以下配置：
```
registry=https://registry.npmmirror.com
timeout=300000
fetch-retries=5
fetch-retry-mintimeout=20000
fetch-retry-maxtimeout=120000
progress=false
loglevel=warn
```

#### 2. 手动配置npm超时
```bash
# 设置超时时间为5分钟
npm config set timeout 300000

# 设置重试次数
npm config set fetch-retries 5

# 设置重试间隔
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
```

### 方案三：单独安装ffmpeg-static

#### 1. 先安装其他依赖
```bash
# 临时移除ffmpeg-static
npm install --ignore-scripts

# 或者手动安装其他包
npm install bcryptjs cors dotenv express express-rate-limit fluent-ffmpeg multer
```

#### 2. 单独安装ffmpeg-static
```bash
# 使用淘宝镜像单独安装
npm install ffmpeg-static@^5.2.0 --registry=https://registry.npmmirror.com
```

### 方案四：使用cnpm（备选方案）

#### 1. 安装cnpm
```bash
npm install -g cnpm --registry=https://registry.npmmirror.com
```

#### 2. 使用cnpm安装依赖
```bash
cnpm install
```

### 方案五：使用yarn（备选方案）

#### 1. 安装yarn
```bash
npm install -g yarn
```

#### 2. 配置yarn镜像源
```bash
yarn config set registry https://registry.npmmirror.com
```

#### 3. 使用yarn安装
```bash
yarn install
```

## 系统级ffmpeg替代方案

如果ffmpeg-static仍然无法安装，可以使用系统级ffmpeg：

### 1. 安装系统级ffmpeg
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg

# 验证安装
ffmpeg -version
```

### 2. 修改代码使用系统ffmpeg
使用项目中的`upload-system-ffmpeg.js`替换`upload.js`：

```bash
# 备份原文件
cp routes/upload.js routes/upload.backup.js

# 使用系统ffmpeg版本
cp routes/upload-system-ffmpeg.js routes/upload.js
```

### 3. 从package.json移除ffmpeg-static
编辑`package.json`，移除ffmpeg-static依赖：
```json
{
  "dependencies": {
    // 移除这一行
    // "ffmpeg-static": "^5.2.0"
  }
}
```

## 完整安装步骤

### 推荐步骤（方案一+二）

1. **清理环境**
```bash
cd /var/www/love4lili/server
rm -rf node_modules
rm -f package-lock.json
npm cache clean --force
```

2. **配置npm**
```bash
# 使用项目中的.npmrc配置，或手动设置
npm config set registry https://registry.npmmirror.com
npm config set timeout 300000
npm config set fetch-retries 5
```

3. **安装依赖**
```bash
npm install
```

4. **验证安装**
```bash
# 检查ffmpeg-static是否安装成功
node -e "console.log(require('ffmpeg-static'))"

# 启动服务测试
npm start
```

## 故障排除

### 如果仍然超时
1. 检查服务器网络连接
2. 尝试使用VPN或代理
3. 联系服务器提供商检查网络限制
4. 使用系统级ffmpeg替代方案

### 常见错误处理

#### 权限错误
```bash
sudo chown -R $USER:$USER ~/.npm
sudo chown -R $USER:$USER node_modules
```

#### 磁盘空间不足
```bash
# 检查磁盘空间
df -h

# 清理npm缓存
npm cache clean --force
```

#### 网络连接问题
```bash
# 测试网络连接
curl -I https://registry.npmmirror.com

# 检查DNS
nslookup registry.npmmirror.com
```

## 预防措施

1. **使用Docker部署**
   - 创建Dockerfile预装所有依赖
   - 避免生产环境直接npm install

2. **依赖锁定**
   - 提交package-lock.json到版本控制
   - 使用npm ci而不是npm install

3. **镜像源配置**
   - 在项目中包含.npmrc文件
   - 团队统一使用相同的镜像源

## 联系支持

如果以上方案都无法解决问题，请：
1. 收集完整的错误日志
2. 记录服务器环境信息（Node.js版本、npm版本、操作系统版本）
3. 联系技术支持团队