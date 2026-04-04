# love4lili_flutter

Love4Lili - 情侣约会记录与规划 Flutter 客户端

## 启动 Android 模拟器

```bash
# 1. 启动 Pixel 7 模拟器
flutter emulators --launch Pixel_7

# 2. 等模拟器窗口出来后，运行应用
flutter run -d emulator-5554
```

如果 `flutter emulators --launch` 失败，直接用 emulator 命令：

```bash
~/Library/Android/sdk/emulator/emulator -avd Pixel_7 -no-snapshot-load
```

## 热键

- `r` — 热重载
- `R` — 热重启
- `q` — 退出

## 查看日志

### 方式一：adb logcat

```bash
# 只看 Flutter 相关日志
adb logcat -s flutter

# 看所有日志
adb logcat
```

### 方式二：Flutter DevTools

```bash
# 单独启动 DevTools
flutter pub global run devtools
```

运行 `flutter run` 后终端会打印 DevTools URL，复制到浏览器打开即可。

DevTools 功能：
- **Logging** — 查看所有日志
- **Network** — 查看 API 请求/响应
- **Widget Inspector** — 检查 UI 组件树
- **Performance** — 性能分析

### 方式三：flutter run 自带日志

`flutter run` 运行后终端会直接显示日志输出。

## 常见问题

### 模拟器启动失败 "Running multiple emulators"

旧进程没杀干净，清理后重开：

```bash
# 杀掉所有模拟器进程
killall -9 qemu-system-aarch64
killall -9 crashpad_handler
killall -9 netsimd

# 重新启动
flutter emulators --launch Pixel_7
```

### "Error connecting to the service protocol"

DevTools 连不上，不影响 app 运行。app 已正常安装到模拟器。

可尝试：

```bash
flutter run -d emulator-5554 --enable-software-rendering
```

### NDK / CMake / Build-Tools 下载失败

网络问题，需要配置代理。在 `android/gradle.properties` 中添加：

```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=7897
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=7897
```

或手动安装 SDK 组件：

```bash
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "ndk;28.2.13676358"
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "cmake;3.22.1"
```

### "Entrypoint isn't within a Flutter pub root"（Android Studio）

确保打开的是 `flutter_app/` 目录（包含 `pubspec.yaml`），不是父目录或子目录。

如果仍有问题，删除 `.idea` 缓存后重新打开：

```bash
rm -rf flutter_app/.idea
```

## 构建 Release APK

```bash
flutter build apk --release
```

APK 输出路径：`build/app/outputs/flutter-apk/app-release.apk`

## 后端 API

生产环境指向公网服务器 `http://8.140.227.83`，配置在 `lib/config/api_config.dart`。
