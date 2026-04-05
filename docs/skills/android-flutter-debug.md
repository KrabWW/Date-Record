---
name: android-flutter-debug
description: Use when debugging a Flutter app running on an Android emulator via CLI. Covers the full cycle: launch emulator/app, take screenshots to observe UI, interact via adb input commands, capture and diagnose error logs, fix code, and verify the fix.
---

# Android Flutter Emulator Debugging

```text
NO FIXES WITHOUT SEEING THE SCREEN.
NO DIAGNOSIS WITHOUT LOGS.
NO LOGS WITHOUT UNDERSTANDING WHICH LOG CHANNEL TO CHECK.
```

## When to Use

- User reports "app crashed" or "something went wrong" on Android emulator
- Need to interact with Flutter app running on emulator (tap, type, navigate)
- Need to capture and diagnose Flutter error logs
- After code changes, need to verify the fix visually

## Phase 1: Environment Setup

### Check Emulator Status

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator"
adb devices
# Expected: emulator-5554    device
```

If no emulator:
```bash
$HOME/Library/Android/sdk/emulator/emulator -avd <avd_name> -no-snapshot-load &
```

### Start Backend Server (if needed)

```bash
cd server && npm run dev
# Verify: curl -s http://localhost:3001/api/auth/login -X POST -H "Content-Type: application/json" -d '{"email":"test","password":"test"}'
```

### Start Flutter App

```bash
cd flutter_app   # CRITICAL: must be in flutter_app/ subdirectory, NOT project root!
flutter clean   # ALWAYS clean before rebuild
flutter run -d emulator-5554
```

**WARNING**: If you run `flutter run` from the project root instead of `flutter_app/`, the build will silently use wrong/cached code. Always verify the working directory.

Run in background to keep CLI free:
```bash
flutter run -d emulator-5554 2>&1 | tail -20   # background with TaskUpdate
```

### API Config Switching

Android emulator accesses host machine via `10.0.2.2`, NOT `localhost` or `127.0.0.1`.

```dart
// api_config.dart — toggle _useLocal
static const String _localServer = 'http://10.0.2.2:3001';
static const bool _useLocal = true;
```

## Phase 2: Observe (See the Screen)

### Take Screenshot

```bash
adb -s emulator-5554 shell screencap -p /sdcard/screen.png
adb -s emulator-5554 pull /sdcard/screen.png /tmp/flutter_screen.png
```

### View Screenshot

Use the **Read tool** on the `.png` file. Claude can see images directly.

### OCR Error Text from Red Screens

Flutter framework exceptions may NOT appear in logcat. Use image analysis:

```bash
# First try logcat
adb -s emulator-5554 logcat -d -s flutter | tail -80
```

If no exception found, use OCR on the screenshot to extract the error text:
- Use `mcp__zai-mcp-server__extract_text_from_screenshot` or `mcp__4_5v_mcp__analyze_image`
- Prompt: "Extract all error text, exception type, and stack trace"

## Phase 3: Interact (Control the App)

### Tap

```bash
# Coordinates are in absolute pixels (1080x2400 for typical emulator)
adb -s emulator-5554 shell input tap <x> <y>
```

**Finding coordinates**: Take a screenshot, read it with the Read tool. The image is displayed at reduced size — multiply coordinates by the scale factor shown (e.g., "displayed at 900x2000, multiply by 1.20 to map to original 1080x2400").

### Type Text

```bash
adb -s emulator-5554 shell input text "hello"
```

**CRITICAL — Special Characters**:

| Character | Method | Command |
|-----------|--------|---------|
| `@` | keyevent 77 | `adb shell input keyevent 77` |
| Space | Works normally | `adb shell input text "hello world"` |
| `.` | Works normally | `adb shell input text "test.com"` |
| `%40` | Does NOT work | Don't use URL encoding, it types literally |

**Example — typing email**:
```bash
adb shell input tap 540 820          # tap email field
adb shell input text "krab"          # type local part
adb shell input keyevent 77          # type @
adb shell input text "qq.com"        # type domain
```

### Clear / Backspace

```bash
# Single backspace
adb shell input keyevent KEYCODE_DEL   # or keyevent 67

# Clear field (repeat backspace)
for i in $(seq 1 15); do adb shell input keyevent 67; done
```

### Navigation

```bash
adb shell input keyevent KEYCODE_BACK   # 4  — system back
adb shell input keyevent KEYCODE_ENTER  # 66 — confirm/submit
adb shell input keyevent KEYCODE_DOWN   # 20 — scroll down
adb shell input keyevent KEYCODE_UP     # 19 — scroll up
```

## Phase 4: Diagnose (Find the Error)

### Step 1 — Flutter Dio Logs (Network Errors)

```bash
adb -s emulator-5554 logcat -d -s flutter | tail -80
```

Dio logger shows formatted boxes with: Request URL, Headers, Body, Response status, Response body. Look for:
- `DioError` / `DioExceptionType.badResponse`
- HTTP status codes (401, 404, 429, 500)
- Error response body

### Step 2 — Flutter Framework Exceptions

**These may NOT appear in `adb logcat -s flutter`!** The Dio interceptor only logs network errors.

If logcat shows no exception but the screen is red:
1. Take a screenshot
2. Use OCR/image analysis to read the error text
3. Common framework exceptions: type cast errors, null safety, missing localizations

### Step 3 — Full Process Logs (by PID)

Find the Flutter app PID, then grep all logs:
```bash
# Find PID
adb shell ps | grep flutter
# Or from logcat timestamp pattern

# Get ALL logs from that process
adb -s emulator-5554 logcat -d | grep "<PID>" | grep -i -E "exception|error|fatal" | tail -30
```

### Step 4 — Clear Logs for Fresh Capture

```bash
adb -s emulator-5554 logcat -c
# Tell user: "please perform the action now"
# Then: adb -s emulator-5554 logcat -d -s flutter | tail -80
```

### Common Error Patterns

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| Red screen after `showDatePicker` | Missing `flutter_localizations` | `pubspec.yaml` + `main.dart` |
| `type 'X' is not a subtype of type 'Y'` | API returns different type than expected (e.g. `[]` vs `{}`) | Model fromJson / casting code |
| 401 on all requests | Token expired or not saved | Auth provider, secure storage |
| 429 Too Many Requests | Rate limiting triggered | Wait 15 min or use local backend |
| 404 on `/api/couples/me` | User has no couple space yet | Normal — show setup page |
| App stuck on splash | Backend unreachable | Check backend is running, API config |

## Phase 5: Fix & Verify

1. **Edit code** — Use Edit/Write tools to fix the root cause
2. **Rebuild** — `flutter clean && flutter run -d emulator-5554` (background)
3. **Wait for compilation** — Full build 2-5 min, incremental ~30s
4. **Screenshot to confirm** — Take screenshot, verify fix visually
5. **Test the flow** — Interact via adb to reproduce the scenario that previously failed

## Phase 6: Autonomous Debug Loop (e2e_test.sh)

```text
NO PATROL. adb + screenshots. Fast cycle.
```

Use `flutter_app/scripts/e2e_test.sh` for structured end-to-end testing without Patrol.

### Why Not Patrol

Patrol builds a full test APK (2-5 min), requires Android Test Orchestrator, and `pumpAndTrySettle` / `waitUntilVisible` can hang indefinitely on slow network. The adb approach uses the already-running debug app and interacts via CLI — seconds per cycle, not minutes.

### Pipeline Mode (recommended)

```bash
cd flutter_app
./scripts/e2e_test.sh run                          # Full pipeline with retry + auto-progression
./scripts/e2e_test.sh run --max-retries 5           # Custom retry limit
```

Pipeline stages (runs in order, auto-progresses on pass):
```
Stage 1/4: login          -> 注册登录
Stage 2/4: create-couple  -> 创建情侣空间
Stage 3/4: join-couple    -> 加入空间（无效邀请码验证）
Stage 4/4: home           -> 首页加载
```

**Flow:**
```
+----------------------------------------------------------------+
|  ./scripts/e2e_test.sh run                                     |
|                                                                |
|  Stage 1/4: login                                             |
|    +-- [CONFIRMED] login -> auto-progress to stage 2           |
|    +-- [SCENARIO_FAILED] -> retry (up to MAX_RETRIES=3)        |
|    +-- [HUMAN_INTERVENTION_NEEDED] after 3 failures -> STOP    |
|        Claude reads screenshots + logs, fixes code,            |
|        hot reloads, then runs: ./scripts/e2e_test.sh login     |
|                                                                |
|  Stage 2/4: create-couple  (only if stage 1 passed)           |
|  Stage 3/4: join-couple    (only if stage 2 passed)           |
|  Stage 4/4: home           (only if stage 3 passed)           |
|                                                                |
|  [RESULT] ALL PASSED                                          |
+----------------------------------------------------------------+
```

### Key Output Markers (parseable by Claude)

| Marker | Meaning | Action |
|--------|---------|--------|
| `[CONFIRMED] scenario` | Scenario passed, verified | Auto-progress to next |
| `[SCENARIO_FAILED] scenario (attempt N/M)` | Failed, will retry | Wait for next attempt |
| `[RETRY] scenario -- attempt N/M` | Retrying | Wait for result |
| `[HUMAN_INTERVENTION_NEEDED] scenario` | Max retries exceeded | Read screenshots + logs, fix code |
| `[PROGRESS] scenario passed -> next scenario` | Moving on | No action needed |
| `[PROGRESS] scenario needs human intervention -> STOPPING` | Pipeline halted | Fix and resume manually |
| `[RESULT] ALL PASSED` | All stages passed | Done |
| `[RESULT] INTERVENTION_NEEDED` | Blocked, needs fix | Fix + re-run the blocked scenario |

### Single Scenario Mode

```bash
./scripts/e2e_test.sh login                # Test login flow only
./scripts/e2e_test.sh create-couple        # Test couple space creation
./scripts/e2e_test.sh join-couple          # Test join with invalid code
./scripts/e2e_test.sh home                 # Test home page loads
./scripts/e2e_test.sh add-record           # Test creating a record
./scripts/e2e_test.sh logout               # Test logout flow
./scripts/e2e_test.sh full                 # All scenarios (no retry, no stop)
./scripts/e2e_test.sh reset                # Clear logcat + fresh screenshot
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `EMU_ID` | `emulator-5554` | Emulator serial |
| `EMAIL` | `krab@qq.com` | Login email |
| `PASSWORD` | `123456` | Login password |
| `SCREENSHOT_DIR` | `/tmp/flutter_e2e` | Where screenshots are saved |
| `MAX_RETRIES` | `3` | Max retries per scenario before human intervention |

### Confirmation Mechanism

Each scenario ends with `confirm_scenario()` which:
1. Waits 2s for UI to settle
2. Takes a `_confirmed.png` screenshot
3. Captures `_confirm_logcat.txt`
4. Checks for Flutter/Dart errors in logcat
5. Outputs `[CONFIRMED]` on success, or `[FAIL]` on error

This prevents the script from endlessly looping on a passed scenario.

### Hot Reload vs Full Rebuild

| Change Type | Method | Speed |
|-------------|--------|-------|
| Dart logic fix (bug fix, null safety) | Hot reload (`r` in flutter process) | ~2s |
| New dependency, asset, or native change | Full rebuild (`flutter clean && flutter run`) | 2-5 min |
| Route/config change | Hot restart (`R` in flutter process) | ~10s |

### Coordinate Reference (1080x2400 emulator)

The script uses hardcoded coordinates. If the UI layout changes, adjust in `e2e_test.sh`:

| Element | Approximate (x, y) |
|---------|-------------------|
| Login email field | (540, 720) |
| Login password field | (540, 870) |
| Login button | (540, 1020) |
| Couple setup -- create button | (540, 920) |
| Create couple -- name field | (540, 680) |
| Create couple -- date field | (540, 800) |
| Create couple -- submit | (540, 1050) |

To find correct coordinates: take a screenshot, read it with the Read tool, and estimate from the image dimensions.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The logs are clean, no errors" | Flutter framework exceptions may not appear in Dio logcat -- check the screen |
| "I'll just read the code to find the bug" | Screenshot first. See what the user sees. |
| "Let me fix without confirming the error" | Always confirm the root cause via logs or OCR before editing code |
| "I can type `@` with adb input text" | `@` requires `keyevent 77`, direct text input fails silently |
| "The emulator can reach localhost:3000" | Emulator needs `10.0.2.2` to reach the host machine |
| "I'll keep retrying the same scenario" | After MAX_RETRIES (default 3), STOP and request human intervention |

## Quick Reference -- adb Commands Cheat Sheet

```bash
# === SETUP ===
adb devices                                    # list devices
adb -s emulator-5554 logcat -c                 # clear logs

# === OBSERVE ===
adb -s emulator-5554 shell screencap -p /sdcard/screen.png
adb -s emulator-5554 pull /sdcard/screen.png /tmp/screen.png
adb -s emulator-5554 logcat -d -s flutter     # Flutter logs only

# === INTERACT ===
adb -s emulator-5554 shell input tap X Y       # tap coordinates
adb -s emulator-5554 shell input text "hello"  # type text
adb -s emulator-5554 shell input keyevent 67   # backspace
adb -s emulator-5554 shell input keyevent 77   # @ symbol
adb -s emulator-5554 shell input keyevent 66   # enter
adb -s emulator-5554 shell input keyevent 4    # back

# === DIAGNOSE ===
adb -s emulator-5554 logcat -d -s flutter | grep -i "error" | tail -20
adb -s emulator-5554 logcat -d | grep "<PID>" | grep -i "exception" | tail -20
```

## Discovered Patterns (Evolution Log)

> **Instructions**: When you discover a new debugging pattern during a session, append it to this list. Each entry should capture: date, symptom, root cause, and fix. This builds institutional knowledge over time.

### 2026-04-05 -- Session 1: Love4Lili Flutter App

**P1: Date picker crash -- missing localizations**
- Symptom: App crashes (red screen) when tapping date picker
- Root cause: `showDatePicker` uses `locale: Locale('zh', 'CN')` but `flutter_localizations` is not configured
- Fix: Add `flutter_localizations` SDK dependency in `pubspec.yaml` + add `localizationsDelegates`, `supportedLocales`, `locale` in `MaterialApp.router`
- Files: `pubspec.yaml`, `lib/main.dart`

**P2: Type cast crash on empty API response field**
- Symptom: `type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>?' in type cast`
- Root cause: API returns `mood_distribution: []` (empty List) when no data, but code does `as Map<String, dynamic>?`
- Fix: Check type before casting: `stats['mood_distribution'] is Map ? ... : <String, dynamic>{}`
- Files: `lib/pages/home/home_page.dart:371`

**P3: `@` symbol not typed via adb input text**
- Symptom: Email field shows `%40` or no `@` when using `adb shell input text`
- Root cause: `@` is interpreted by adb shell; `%40` is typed literally, not decoded
- Fix: Use `adb shell input keyevent 77` to type `@`

**P4: Flutter exceptions invisible in logcat**
- Symptom: Red error screen but `adb logcat -s flutter` shows no exception
- Root cause: Dio interceptor only logs network errors; Flutter framework exceptions (type casts, widget errors) bypass it
- Fix: Take screenshot + use OCR/image analysis to read error text from screen

**P5: Android emulator can't reach host localhost**
- Symptom: App can't connect to local backend at `localhost:3001`
- Root cause: Android emulator has its own network namespace; `localhost` refers to the emulator itself
- Fix: Use `10.0.2.2` as the host machine address in API config

**P6: Backend 429 rate limiting during testing**
- Symptom: Login returns 429 "登录尝试次数过多, 请15分钟后再试"
- Root cause: Multiple failed login attempts triggered server-side rate limiter
- Fix: Switch to local backend, or wait 15 minutes, or restart backend to reset rate limit

**P7: GoRouter redirect not firing after login**
- Symptom: Login API succeeds (200) but page stays on login screen, no navigation
- Root cause: GoRouter's `refreshListenable` with `ref.listen` doesn't reliably trigger redirect. When `coupleState.isLoading` is true during redirect evaluation, it returns null and stays on `/auth`.
- Fix: Add explicit `context.go('/')` or `context.go('/couple-setup')` in login page after successful login, don't rely solely on GoRouter redirect

**P8: `flutter run` from wrong directory -- changes not reflected**
- Symptom: Code changes (debug prints, navigation fixes) don't appear in the running app
- Root cause: `flutter run` was executed from project root `/Date-Record/` instead of `flutter_app/` subdirectory. Flutter silently used the wrong pubspec or cached old build.
- Fix: ALWAYS `cd flutter_app` before running `flutter run`. Verify with `flutter clean && flutter run` from the correct directory. Check debug print output in logcat to confirm new code is running.

**P9: Type cast crash on empty mood_distribution**
- Symptom: `type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>?' in type cast` on home page
- Root cause: API returns `mood_distribution: []` (empty List) when no data, but code does `as Map<String, dynamic>?`
- Fix: Check type before casting: `stats['mood_distribution'] is Map ? ... : <String, dynamic>{}`
- Files: `lib/pages/home/home_page.dart:371`

### 2026-04-05 -- Session 2: Love4Lili Flutter App

**P10: Patrol test runner hangs on slow network / async waits**
- Symptom: `patrol test` hangs indefinitely, no output, app appears frozen
- Root cause: `pumpAndTrySettle` and `waitUntilVisible` block until widget tree settles. On slow network or infinite loading states, they never return. Patrol also requires full APK rebuild (2-5 min) per run, making iteration too slow for debug loops.
- Fix: Use `flutter_app/scripts/e2e_test.sh` -- adb-based test runner that interacts with the already-running debug app. No rebuild needed for Dart-only fixes (hot reload). Hot reload cycle: ~2s vs Patrol's ~5min.
- Files: `flutter_app/scripts/e2e_test.sh`, SKILL.md Phase 6

**P11: Script loops on passed scenario -- no confirmation mechanism**
- Symptom: After login succeeds, the debug loop keeps re-running login instead of moving to create-couple
- Root cause: No confirmation step to verify scenario success and trigger progression. The script just reported results without deciding whether to move on.
- Fix: Added `confirm_scenario()` function + `run_pipeline` mode with auto-progression. Each scenario ends with a confirmation check (screenshot + logcat). On `[CONFIRMED]`, the pipeline automatically advances to the next stage.
- Files: `flutter_app/scripts/e2e_test.sh`

**P12: Infinite retry without escalation -- no human intervention**
- Symptom: Script retries a failing scenario indefinitely, never stopping
- Root cause: No retry limit. If a bug requires code changes beyond automated capability, the loop runs forever.
- Fix: Added `MAX_RETRIES` (default 3). After exhausting retries, outputs `[HUMAN_INTERVENTION_NEEDED]` and stops the pipeline. Claude reads the screenshots/logs, fixes the code, and resumes manually.

---
<!-- Append new patterns below this line. Format:
### YYYY-MM-DD -- Session N: Project Name

**PN: Short title**
- Symptom: What the user sees
- Root cause: Why it happens
- Fix: How to resolve it
- Files: affected files
-->
