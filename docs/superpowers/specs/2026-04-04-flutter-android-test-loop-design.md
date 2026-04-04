# Flutter Android 自动化测试修复循环工作流设计

**日期**: 2026-04-04
**项目**: Love4Lili Flutter Android 端
**目标**: 设计一套自动化测试 → 日志检查 → 修复 → 循环的工作流，覆盖所有功能开发点，结合 agent 团队并行与串行执行。

---

## 背景

Flutter Android 端在功能实现过程中频繁出现 bug，手动触发测试、读取 logcat、修复代码的流程耗时且容易中断。需要一套自动化工作流：

- **自动运行** patrol 集成测试
- **自动读取** adb logcat 定位错误
- **自动修复** 常见错误（类型错误、import、API 字段名等）
- **循环重试**，超过阈值则跳过并记录
- **并行执行** 不依赖模拟器的代码编写任务
- **进度持久化** 写入 `flutter_app/progress.txt`

---

## 技术选型

| 组件 | 工具 | 用途 |
|------|------|------|
| 任务管理 | OpenSpec tasks.md | 定义所有功能点，追踪状态 |
| 测试框架 | patrol CLI (`patrol test`) | Flutter Android 集成测试（原生层交互） |
| 日志采集 | `adb logcat` | Android 运行日志 |
| 修复循环 | ralph-loop | 同一 prompt 迭代执行，每次看到之前的工作 |
| 并行执行 | dispatching-parallel-agents skill | code-only 任务并行 |
| 进度追踪 | `flutter_app/progress.txt` | 时间戳 + 状态，唯一真实来源 |

---

## 架构

```
OpenSpec tasks.md  ←  所有 Flutter 功能点（带 type 标记）
       │
       ▼
Coordinator Agent（主会话）
       │
       ├─ 识别 [code] 类型任务（不依赖模拟器）
       │    └─→ Agent Team（parallel）
       │          ├── agent-A: 写 patrol 测试代码
       │          ├── agent-B: 写 service/model 代码
       │          └── agent-C: 写 widget 代码
       │                ↓ 完成后运行编译门控
       │                  dart analyze && flutter build apk --debug
       │                  失败 → 串行补救（不阻断 emulator 阶段，记录到 progress.txt）
       │
       └─ 识别 [emulator] 类型任务（需模拟器，顺序执行）
              前置条件: adb devices 确认模拟器在线，取第一个 emulator-XXXX
              └─→ Ralph Loop（每个 task 独立跑）
                    --max-iterations 5
                    --completion-promise "DONE"

                    每次迭代:
                      1. patrol test integration_test/[module]_test.dart
                         -d $(adb devices | grep emulator | awk '{print $1}' | head -1)
                      2. 失败 → adb logcat -d | grep -E "E/flutter|E/AndroidRuntime|Fatal" | tail -100
                      3. 分析错误 → 自动修复 or pause
                      4. 输出 <promise>DONE</promise> 当测试通过

                    max hit (5次) → 输出 <promise>BLOCKED</promise>
                    通过          → 输出 <promise>DONE</promise>
                    人工决策      → 输出 <promise>NEEDS_HUMAN</promise>
```

---

## tasks.md 结构

每个功能点拆分为两条 task：一条 `[code]`（可并行），一条 `[emulator]`（串行 ralph-loop）。

```markdown
## Tasks

### Auth 模块
- [ ] [code] 实现 AuthService.login() / register()
- [ ] [code] 写 auth_flow patrol 测试
- [ ] [emulator] 跑 auth_flow patrol + fix loop

### Records 模块
- [ ] [code] 实现 RecordService.fetchList() / create() / update()
- [ ] [code] 写 records patrol 测试
- [ ] [emulator] 跑 records patrol + fix loop

### Wishlist 模块
- [ ] [code] 实现 WishlistService CRUD
- [ ] [code] 写 wishlist patrol 测试
- [ ] [emulator] 跑 wishlist patrol + fix loop

### Gallery 模块
- [ ] [code] 实现 MediaService 上传/列表
- [ ] [code] 写 gallery patrol 测试
- [ ] [emulator] 跑 gallery patrol + fix loop

### Couple Setup 模块
- [ ] [code] 实现 CoupleService 创建/加入
- [ ] [code] 写 couple_setup patrol 测试
- [ ] [emulator] 跑 couple_setup patrol + fix loop

## Blocked（需人工介入）
<!-- 自动填入，格式: ⚠️ [task] 失败 5/5，错误摘要，详见 flutter_app/logs/errors/[task].log -->
```

---

## Ralph Loop Prompt 模板

每个 `[emulator]` task 使用以下 prompt 触发：

```
/ralph-loop "Run patrol integration test for [MODULE].

Precondition: run `adb devices` and pick the first emulator-XXXX device ID.

Test command:
  cd flutter_app
  patrol test integration_test/[module]_test.dart -d <DEVICE_ID>

If the test FAILS:
1. Collect logs:
   adb logcat -d | grep -E 'E/flutter|E/AndroidRuntime|Fatal exception' | tail -100
2. Identify root cause.
3. Auto-fix if error type is: type mismatch, missing import, wrong API field name, null check failure.
4. If fix requires human judgment (UI behavior ambiguity, permission policy, data schema conflict):
   - Append the question to flutter_app/HUMAN_REVIEW.md with context
   - Output <promise>NEEDS_HUMAN</promise>
5. If this is iteration 5 (max):
   - Write full log to flutter_app/logs/errors/[module].log
   - Append to flutter_app/progress.txt: [TIMESTAMP] ⚠️ [module] BLOCKED (5/5 failed)
   - Output <promise>BLOCKED</promise>

If the test PASSES:
- Mark task ✅ in openspec/changes/flutter-android/tasks.md
- Append to flutter_app/progress.txt: [TIMESTAMP] ✅ [module] PASSED (iteration N/5)
- Output <promise>DONE</promise>" --max-iterations 5 --completion-promise "DONE"
```

**注意**：ralph-loop 的 stop hook 监听 `<promise>` tag。`DONE`、`NEEDS_HUMAN`、`BLOCKED` 三个值都会终止当前 task 的 loop，coordinator 根据返回值决定下一步。

---

## 错误分类与处理策略

| 错误类型 | 自动修复 | 示例 |
|---------|---------|------|
| 类型不匹配 | ✅ | `int` 期望收到 `String` |
| Import 缺失 | ✅ | `package:xxx not found` |
| API 字段名错误 | ✅ | `snake_case` vs `camelCase` |
| 空指针异常 | ✅ | `Null check operator used on null` |
| UI 行为歧义 | ❌ → NEEDS_HUMAN | 弹窗是否需要关闭 |
| 权限策略 | ❌ → NEEDS_HUMAN | 相册权限拒绝后的行为 |
| 数据库结构冲突 | ❌ → NEEDS_HUMAN | schema 迁移决策 |
| 连续 5 次失败 | ❌ → BLOCKED | 写 logs/errors/[module].log |

---

## progress.txt 格式

唯一文件：`flutter_app/progress.txt`（ralph-loop 和 coordinator 都追加写入此文件）。

```
[2026-04-04 10:00] 🚀 工作流启动，共 15 tasks (10 code, 5 emulator)
[2026-04-04 10:05] ✅ [code] auth service + tests 写入完成
[2026-04-04 10:10] ⚡ 编译门控通过: dart analyze OK, flutter build apk --debug OK
[2026-04-04 10:23] ✅ auth_flow patrol PASSED (iteration 2/5)
[2026-04-04 10:45] ⚠️ records patrol BLOCKED (5/5 failed) → logs/errors/records.log
[2026-04-04 11:02] ✅ wishlist patrol PASSED (iteration 1/5)
[2026-04-04 11:30] 🤔 gallery patrol NEEDS_HUMAN → HUMAN_REVIEW.md
```

---

## 并行 Agent 团队规则

`dispatching-parallel-agents` skill 触发条件：
- tasks.md 中有 2+ 条 `[code]` 类型 pending 任务
- 各 agent 操作不同文件（service 层、integration_test 层、widget 层天然隔离）
- 不涉及模拟器

**编译门控**（并行阶段完成后，进入 emulator 阶段前）：
```bash
cd flutter_app
dart analyze lib/
flutter build apk --debug --no-pub
```
- 通过 → 继续 emulator 阶段
- 失败 → coordinator 串行修复编译错误，记录到 progress.txt，然后继续

**单 agent 失败回退**：若某个 parallel agent 中途失败，coordinator 将该 agent 的任务降级为串行执行（不阻断其他 agent）。

---

## 文件结构

```
flutter_app/
├── integration_test/          ← patrol 测试文件（agent-team 生成）
│   ├── auth_flow_test.dart
│   ├── records_test.dart
│   ├── wishlist_test.dart
│   ├── gallery_test.dart
│   └── couple_setup_test.dart
├── logs/
│   └── errors/               ← ralph-loop 失败日志（BLOCKED 时写入）
│       ├── records.log
│       └── gallery.log
├── HUMAN_REVIEW.md           ← 需人工决策的问题（唯一位置）
└── progress.txt              ← 实时进度（唯一位置）

openspec/
└── changes/
    └── flutter-android/
        ├── tasks.md          ← 任务状态（[code]/[emulator]，带 ✅/⚠️）
        └── proposal.md
```

---

## 执行流程（Step by Step）

1. **初始化**
   - coordinator 读 `openspec/changes/flutter-android/tasks.md`
   - 分组：`[code]` 批次 + `[emulator]` 有序队列
   - 确认模拟器在线：`adb devices | grep emulator`（不在线则 pause 提示用户）
   - 写入 `flutter_app/progress.txt` 启动记录

2. **并行阶段**
   - `dispatching-parallel-agents` 处理所有 `[code]` 任务
   - 各 agent 操作独立文件，完成后标记 tasks.md

3. **编译门控**
   - `dart analyze lib/ && flutter build apk --debug`
   - 失败 → coordinator 串行修复 → 重新通过门控
   - 通过 → 记录到 progress.txt

4. **串行阶段**
   - 依次对每个 `[emulator]` 任务使用 ralph-loop prompt 模板
   - 监听 promise：DONE / BLOCKED / NEEDS_HUMAN

5. **结果处理**
   - `DONE` → 更新 tasks.md ✅ + progress.txt
   - `BLOCKED` → 写 logs/errors/[module].log + tasks.md ⚠️ + progress.txt
   - `NEEDS_HUMAN` → 追加 HUMAN_REVIEW.md，暂停等待用户回复，回复后继续

6. **归档**
   - 所有任务处理完：运行 `/opsx:archive`（OpenSpec CLI 命令，将 tasks.md 移至 archive/，生成 summary）
   - git commit progress.txt + tasks.md + logs/

---

## 成功标准

**[code] 并行阶段**：
- 所有 `[code]` tasks 标记 ✅
- 编译门控通过（dart analyze 零错误，apk --debug 构建成功）

**[emulator] 串行阶段**：
- 所有 `[emulator]` tasks 状态为 ✅ 或 ⚠️（无遗漏）
- BLOCKED 任务有对应 `logs/errors/*.log`
- NEEDS_HUMAN 问题已得到用户回复并处理

**整体**：
- `flutter_app/progress.txt` 有完整时间线记录（每个 task 至少一条记录）
- `openspec/changes/flutter-android/tasks.md` 无 `[ ]` 未处理项
