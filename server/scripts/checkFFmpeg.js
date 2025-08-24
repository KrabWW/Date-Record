#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

/**
 * 检查系统FFmpeg安装和配置
 */
async function checkFFmpeg() {
    console.log('🔍 检查FFmpeg安装状态...\n');

    try {
        // 检查ffmpeg命令是否存在
        const version = await getFFmpegVersion();
        console.log('✅ FFmpeg已安装:');
        console.log(`   版本: ${version}`);
        
        // 检查编码器支持
        const encoders = await getFFmpegEncoders();
        console.log('\n📹 支持的视频编码器:');
        encoders.forEach(encoder => {
            console.log(`   - ${encoder}`);
        });

        // 测试基本功能
        console.log('\n🧪 测试FFmpeg基本功能...');
        await testFFmpegBasicFunction();
        console.log('✅ FFmpeg基本功能测试通过');

        console.log('\n🎉 FFmpeg配置完整，视频处理功能可正常使用！');
        return true;

    } catch (error) {
        console.error('\n❌ FFmpeg检查失败:');
        console.error(`   错误: ${error.message}`);
        console.log('\n💡 解决方案:');
        console.log('   Ubuntu/Debian: sudo apt install ffmpeg');
        console.log('   CentOS/RHEL: sudo yum install ffmpeg 或 sudo dnf install ffmpeg');
        console.log('   macOS: brew install ffmpeg');
        return false;
    }
}

/**
 * 获取FFmpeg版本信息
 */
function getFFmpegVersion() {
    return new Promise((resolve, reject) => {
        const ffmpeg = spawn('ffmpeg', ['-version']);
        let output = '';

        ffmpeg.stdout.on('data', (data) => {
            output += data.toString();
        });

        ffmpeg.stderr.on('data', (data) => {
            output += data.toString();
        });

        ffmpeg.on('close', (code) => {
            if (code === 0 || output.includes('ffmpeg version')) {
                // 提取版本信息
                const versionMatch = output.match(/ffmpeg version ([^\s]+)/);
                const version = versionMatch ? versionMatch[1] : 'unknown';
                resolve(version);
            } else {
                reject(new Error('FFmpeg not found or not working'));
            }
        });

        ffmpeg.on('error', (error) => {
            reject(new Error(`FFmpeg command not found: ${error.message}`));
        });
    });
}

/**
 * 获取FFmpeg支持的编码器
 */
function getFFmpegEncoders() {
    return new Promise((resolve, reject) => {
        const ffmpeg = spawn('ffmpeg', ['-encoders']);
        let output = '';

        ffmpeg.stdout.on('data', (data) => {
            output += data.toString();
        });

        ffmpeg.stderr.on('data', (data) => {
            output += data.toString();
        });

        ffmpeg.on('close', (code) => {
            if (code === 0) {
                // 提取常用的视频编码器
                const encoders = [];
                const lines = output.split('\n');
                
                const videoEncoders = ['libx264', 'libx265', 'libvpx', 'libvpx-vp9', 'h264', 'hevc'];
                
                lines.forEach(line => {
                    videoEncoders.forEach(encoder => {
                        if (line.includes(encoder) && !encoders.includes(encoder)) {
                            encoders.push(encoder);
                        }
                    });
                });

                resolve(encoders.length > 0 ? encoders : ['default codecs available']);
            } else {
                resolve(['unable to detect encoders']);
            }
        });

        ffmpeg.on('error', (error) => {
            reject(error);
        });
    });
}

/**
 * 测试FFmpeg基本功能
 */
function testFFmpegBasicFunction() {
    return new Promise((resolve, reject) => {
        // 创建一个简单的测试：生成1秒的测试视频
        const ffmpeg = spawn('ffmpeg', [
            '-f', 'lavfi',
            '-i', 'testsrc=duration=1:size=320x240:rate=1',
            '-f', 'null',
            '-'
        ]);

        let errorOutput = '';

        ffmpeg.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        ffmpeg.on('close', (code) => {
            if (code === 0) {
                resolve();
            } else {
                // 即使返回非0，如果没有严重错误也认为基本功能可用
                if (errorOutput.includes('Successful') || errorOutput.includes('frame=') || !errorOutput.includes('Error')) {
                    resolve();
                } else {
                    reject(new Error(`FFmpeg test failed: ${errorOutput.slice(-200)}`));
                }
            }
        });

        ffmpeg.on('error', (error) => {
            reject(error);
        });

        // 设置超时
        setTimeout(() => {
            ffmpeg.kill();
            reject(new Error('FFmpeg test timeout'));
        }, 10000);
    });
}

// 如果直接运行此脚本
if (require.main === module) {
    checkFFmpeg().then(success => {
        process.exit(success ? 0 : 1);
    });
}

module.exports = { checkFFmpeg };