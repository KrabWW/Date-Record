# Flutter App 自动化 Bug 猎手 — 设计文档

> 日期：2026-04-05
> 项目：Love4Lili Flutter App
> 状态：Approved

## 目标

为 Flutter app 构建自动化测试系统，覆盖所有用户场景，自动发现并记录 bug，对常见 bug 能自动修复并验证。

## 核心设计

三层架构，由快到慢，由结构化到智能化：

| Phase | 驱动者 | 速度 | 用途 |
|-------|--------|------|------|
| 1 结构化遍历 | `bug_hunt.sh`（纯 bash + Maestro） | 分钟级 | 主流程回归，CI 可用 |
| 2 AI 智能探索 | Claude（对话循环 + adb） | 每步 ~5-10s | 发现边界 case 和意外 bug |
| 3 汇总 + 自动修复 | Claude + bash | 视 bug 难度 | 自动修常见 bug，标记复杂 bug |

## Phase 1：结构化遍历

### 原理

使用 Maestro YAML 文件按流程走完所有页面，每个 flow 有 `assertVisible` 断言。失败时自动截图+保存日志。

### Maestro Flow 文件

```
.maestro/
  01_register_and_login.yaml      # 注册 + 登录
  02_create_couple.yaml           # 创建情侣空间
  03_join_couple_invalid.yaml     # 加入空间（无效邀请码）
  04_home_page.yaml               # 首页加载 + 统计
  05_records_flow.yaml            # 记录 CRUD
  06_gallery_flow.yaml            # 相册浏览 + 上传
  07_settings_flow.yaml           # 设置页 + 修改资料
  08_logout_relogin.yaml          # 退出登录 + 重新登录
```

### 主控脚本 `bug_hunt.sh`

```bash
# 用法：
./scripts/bug_hunt.sh                    # 跑所有 flow
./scripts/bug_hunt.sh --phase=1          # 只跑 Phase 1
./scripts/bug_hunt.sh --flow=02          # 只跑指定 flow

# 行为：
# 1. 逐个运行 .maestro/ 下的 flow 文件
# 2. PASS → 记录 ✓
# 3. FAIL → 截图 + logcat 保存到 bug_reports/YYYY-MM-DD/NNN_description/
# 4. 最终输出汇总：X passed, Y failed
```

### Bug 报告格式

```
bug_reports/
  2026-04-05/
    001_home_page_type_cast_error/
      screenshot.png          # 失败时的截图
      logcat.txt              # Flutter 日志
      description.md          # 自动生成的 bug 描述
    002_gallery_upload_crash/
      screenshot.png
      logcat.txt
      description.md
```

### CI 集成

Phase 1 可独立运行，适合放入 CI pipeline：

```yaml
# GitHub Actions
- name: Bug Hunt
  run: cd flutter_app && ./scripts/bug_hunt.sh --phase=1
```

## Phase 2：AI 智能探索

### 原理

Claude 通过截图识别当前页面状态，根据覆盖地图决定下一步操作，通过 adb 执行。发现异常时记录证据但不停止，继续探索其他路径。

### 覆盖地图

维护一个路径覆盖表，标记已探索和未探索的用户路径：

```
主流程覆盖：
[✓] 注册 → 登录 → 首页
[✓] 首页 → 创建空间 → 成功
[✓] 首页 → 加入空间 → 无效邀请码

待探索路径：
[ ] 首页 → 记录列表 → 新建记录 → 保存
[ ] 首页 → 记录列表 → 点击详情 → 编辑 → 删除
[ ] 首页 → 相册 → 上传照片 → 删除
[ ] 首页 → 个人 → 设置 → 修改昵称
[ ] 首页 → 个人 → 设置 → 修改纪念日
[ ] 首页 → 个人 → 退出登录

边界场景：
[ ] 空状态（无记录）的首页显示
[ ] 超长文本输入
[ ] 快速重复点击
[ ] 网络断开时的操作
[ ] 未登录时直接访问受保护页面
```

### AI 探索循环

```
while 存在未覆盖路径:
  1. adb 截图 → Read（AI 识别当前页面）
  2. 根据覆盖地图选择下一个未覆盖路径
  3. 通过 adb/Maestro 执行操作序列
  4. 检查 logcat + 新截图是否异常
  5. 有异常 → 保存证据到 bug_reports/，回退到稳定状态，继续
  6. 无异常 → 标记路径已覆盖
  7. 所有路径覆盖完毕 → 退出
```

### 异常检测方式

- **logcat 错误**：只过滤 `flutter` 进程的 Exception/Error/FATAL/crash
- **红屏检测**：截图后由 AI 判断是否有 Flutter 红色错误屏幕
- **页面卡死**：操作后等待超时，页面没有变化
- **UI 错位**：AI 看截图判断布局是否异常

## Phase 3：汇总 + 自动修复

### Bug 分类

| 类型 | 处理方式 | 示例 |
|------|----------|------|
| 可自动修复 | AI 修代码 → hot reload → 重跑验证 → 标记已修复 | 类型转换、空值检查、路由跳转 |
| 需人工处理 | 标记待处理，提供诊断信息 | UI 布局、业务逻辑、API 兼容性 |

### 自动修复循环

```
for each bug in bug_reports/:
  if 可自动修复:
    1. 分析 logcat + 截图确定根因
    2. 编辑 Dart 源码修复
    3. hot reload 或 rebuild
    4. 重跑相关 Maestro flow 验证
    5. PASS → 标记 FIXED
    6. FAIL → 标记 NEEDS_MANUAL，附上修复尝试记录
  else:
    标记 NEEDS_MANUAL
```

### 最终报告格式

```
Bug Hunting Report — 2026-04-05
==============================
Phase 1 (Maestro): 6 passed, 2 failed
Phase 2 (AI Explore): 3 bugs found
Total: 5 unique bugs

Auto-fixed: 3
  - 001 home_page_type_cast_error (FIXED)
  - 003 gallery_empty_state_crash (FIXED)
  - 005 settings_date_null_error (FIXED)

Needs manual: 2
  - 002 record_edit_photo_rotation (UI layout issue)
  - 004 network_timeout_no_feedback (UX improvement)

Details: bug_reports/2026-04-05/
```

## 文件结构

```
flutter_app/
  .maestro/
    01_register_and_login.yaml
    02_create_couple.yaml
    03_join_couple_invalid.yaml
    04_home_page.yaml              # 待创建
    05_records_flow.yaml           # 待创建
    06_gallery_flow.yaml           # 待创建
    07_settings_flow.yaml          # 待创建
    08_logout_relogin.yaml         # 待创建
  scripts/
    bug_hunt.sh                    # 主控脚本
    e2e_test.sh                    # 手动调试工具（截图、logcat）
  bug_reports/                     # bug 证据输出（.gitignore）
    .gitkeep
```

## 技术约束

- Maestro 2.4.0，通过 `~/.maestro/bin/maestro` 调用
- Flutter app `com.love4lili.love4lili_flutter`，运行在 Android 模拟器
- AI 探索依赖 Claude Code 的 Read 工具读取截图
- Hot reload 需要 `flutter run` 在后台运行
- logcat 错误过滤：只看 flutter 进程，排除 Bluetooth/JavaBinder 等系统噪音
