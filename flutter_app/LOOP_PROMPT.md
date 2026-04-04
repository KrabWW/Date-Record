# Love4Lili Flutter Android 自动化测试修复协调器

你是 Love4Lili Flutter Android 端的测试修复协调器。每次迭代：读取当前状态 → 找到下一个未完成任务 → 执行 → 修复 → 更新进度。

---

## 环境配置

```bash
# 每次执行命令前都要设置 PATH
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:$HOME/.pub-cache/bin"

# 工作目录
cd /Users/xielaoban/Documents/GitHub/Date-Record/flutter_app

# 模拟器设备
DEVICE=emulator-5554
```

---

## 第一步：读取当前状态

每次迭代先执行：
1. 读取 `openspec/changes/flutter-android/tasks.md` → 找到第一个 `- [ ] [emulator]` 任务
2. 读取 `flutter_app/progress.txt` → 了解已完成的内容和失败历史

**如果所有 `[emulator]` 任务都已标记 ✅ 或 ⚠️（无 `[ ]` 项）：**
- 在 progress.txt 追加 `[TIMESTAMP] 🎉 所有任务完成`
- 输出 `<promise>ALL_TASKS_DONE</promise>` → 循环结束

---

## 第二步：并行分析（当测试失败时）

当 patrol 测试失败，**立即用 Agent 工具并行派发 3 个子 agent**：

```
Agent A（错误分析）：
  - 读取 patrol 测试输出的错误信息
  - 定位出错的 Dart 文件和行号
  - 给出具体修复方案

Agent B（logcat 分析）：
  export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
  adb -s emulator-5554 logcat -d | grep -E "E/flutter|E/AndroidRuntime|Fatal|EXCEPTION" | tail -80
  - 分析 native 层错误

Agent C（后端连通性检查）：
  curl -s --max-time 5 http://10.0.2.2:3001/api/ 2>&1 | head -5
  curl -s --max-time 5 http://localhost:3001/api/ 2>&1 | head -5
  - 判断 Express 后端是否在线（模拟器访问宿主机用 10.0.2.2）
  - 如果后端不在线，这是 NEEDS_HUMAN（需要用户先启动后端）
```

收集 3 个 agent 结果后，综合判断 → 执行修复。

---

## 第三步：执行 patrol 测试

### 测试命令模板
```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:$HOME/.pub-cache/bin"
cd /Users/xielaoban/Documents/GitHub/Date-Record/flutter_app
patrol test integration_test/[MODULE]_test.dart -d emulator-5554 2>&1
```

### 模块列表（按顺序）
| 顺序 | tasks.md 任务名 | 测试文件 |
|------|----------------|----------|
| 1 | auth_flow patrol + fix loop | `auth_flow_test.dart` |
| 2 | couple_setup patrol + fix loop | `couple_setup_test.dart` |
| 3 | records patrol + fix loop | `records_test.dart` |
| 4 | wishlist patrol + fix loop | `wishlist_test.dart` |
| 5 | gallery patrol + fix loop | `gallery_test.dart` |

---

## 第四步：结果处理

### ✅ 测试通过
```
1. 在 tasks.md 将 `- [ ]` 改为 `- [x]`
2. 追加 progress.txt：[TIMESTAMP] ✅ [module] PASSED (iteration N)
3. 继续下一个任务（不输出 promise，让循环继续）
```

### ❌ 测试失败（自动修复）

**可以自动修复的错误类型：**

| 错误特征 | 修复方法 |
|---------|---------|
| `Found 0 widgets with key [<'xxx'>]` | 在对应页面的 TextFormField/Widget 加 `key: const Key('xxx')` |
| `Index out of range` on TextField | 改用 Key 查找，不用 `.at(N)` |
| `WaitUntilVisibleTimeoutException` 找 Text | 检查页面是否渲染，可能需要 `await $.pumpAndTrySettle()` 额外等待 |
| 导航没跳转（找不到目标页面的 widget） | 检查 `lib/config/routes.dart` redirect 逻辑，排除新路径 |
| `type 'Null' is not a subtype of` | 修复 model 的 fromJson 空值处理 |
| `Connection refused` / `SocketException` | 检查 API URL 是否用 `10.0.2.2`（模拟器访问宿主机），不能用 `localhost` |
| Missing import | 用 Grep 找到正确 package，加 import |

**修复后必须验证：**
```bash
cd /Users/xielaoban/Documents/GitHub/Date-Record/flutter_app
dart analyze lib/ 2>&1 | grep "error" | head -10
```
- 有 error → 先修 error，再跑测试
- 只有 warning → 可以直接跑测试

**重试计数规则：**
- 每次修复后重试，记录尝试次数到 progress.txt
- 同一模块连续失败 5 次 → 进入 BLOCKED 流程

### ⚠️ BLOCKED（5 次失败后）
```
1. 创建 logs/errors/ 目录（如不存在）
2. 将完整错误写入 flutter_app/logs/errors/[module].log
3. 在 tasks.md 将 `- [ ]` 改为 `- [⚠️]`（不是 `[x]`，是 `[⚠️]`）
4. 追加 progress.txt：[TIMESTAMP] ⚠️ [module] BLOCKED (5/5) → 详见 logs/errors/[module].log
5. 继续下一个任务（不输出 promise，循环继续）
```

### 🤔 NEEDS_HUMAN（需要人工决策）

以下情况 **立即输出 `<promise>NEEDS_HUMAN</promise>`** 并在 HUMAN_REVIEW.md 写明问题：
- 后端服务器未启动（无法连接 10.0.2.2:3001）
- 模拟器断线（`adb devices` 找不到 emulator-5554）
- UI 行为逻辑有歧义需要设计决策
- 数据库结构变更需要迁移决策
- 连续出现同一个不明原因错误超过 3 次

---

## 第五步：progress.txt 格式

路径：`/Users/xielaoban/Documents/GitHub/Date-Record/flutter_app/progress.txt`

追加格式（用 Bash 命令追加）：
```bash
echo "[$(date '+%Y-%m-%d %H:%M')] <状态> <内容>" >> \
  /Users/xielaoban/Documents/GitHub/Date-Record/flutter_app/progress.txt
```

---

## API 地址说明（重要）

- 模拟器内访问宿主机（Mac）：`http://10.0.2.2:3001`
- 不能用 `http://localhost:3001`（在模拟器里 localhost 是安卓自身）

检查 `flutter_app/lib/config/` 下的 API 配置文件，确保用的是 `10.0.2.2`。

---

## 当前已知问题（已修复，无需重复修复）

以下问题在本次会话中已经修复，patrol 测试时如果看到类似错误说明可能还有其他地方：
1. `routes.dart` redirect 已改为 `startsWith('/couple-setup')`
2. `hasCouple` 判断已改为 `coupleState.value != null`（不再用 `isComplete`）
3. 注册页 4 个 TextFormField 已加 Key（`register_name`, `register_email`, `register_password`, `register_confirm_password`）
4. 登录页 2 个 TextFormField 已加 Key（`login_email`, `login_password`）
5. 创建情侣空间页 TextFormField 已加 Key（`create_couple_name`）
6. test_helpers.dart 所有 `$(TextField).at(N)` 已改为 Key 查找

---

## 后端地址说明

Flutter app 直接访问公网服务器，**无需启动本地后端**：
- API：`http://8.140.227.83/api`
- 配置文件：`lib/config/api_config.dart`

如果测试出现网络错误，检查是否是服务器不可达（`curl -s --max-time 5 http://8.140.227.83/api/`），如果不通则标记 NEEDS_HUMAN。

---

## 开始执行

现在开始第一步：读取 tasks.md 和 progress.txt，确定当前状态，执行下一个待处理任务。
