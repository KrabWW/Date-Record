# Bug Hunting Automation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a three-phase automated bug hunting system — Maestro structured traversal, AI-driven exploration, and auto-fix loop — for the Love4Lili Flutter app.

**Architecture:** Phase 1 uses Maestro YAML flows + a bash orchestrator (`bug_hunt.sh`) for CI-ready structured testing. Phase 2 is a Claude-driven exploration loop using adb screenshots and logcat. Phase 3 is a Claude-driven fix-verify loop. Phases 2-3 are instruction-based (no new code), Phase 1 is the main implementation.

**Tech Stack:** Maestro 2.4.0 (`~/.maestro/bin/maestro`), bash, adb, Flutter app `com.love4lili.love4lili_flutter` on Android emulator

**Spec:** `docs/superpowers/specs/2026-04-05-bug-hunting-design.md`

---

## File Structure

```
flutter_app/
  .maestro/
    01_register_and_login.yaml       # ✅ exists — create account + login
    02_create_couple.yaml            # ✅ exists — create couple space
    03_join_couple_invalid.yaml      # ✅ exists — join with invalid code
    04_home_page.yaml                # 🆕 home page load + stats
    05_records_flow.yaml             # 🆕 records list + create record
    06_gallery_flow.yaml             # 🆕 gallery browse + filter
    07_settings_flow.yaml            # 🆕 profile + settings + edit name
    08_logout_relogin.yaml           # 🆕 logout + re-login
  scripts/
    e2e_test.sh                      # ✅ exists — manual debug tool
    bug_hunt.sh                      # 🆕 main orchestrator script
  bug_reports/                       # 🆕 evidence output (gitignored)
    .gitkeep
  .gitignore                         # MODIFY — add bug_reports/
```

---

## Chunk 1: Maestro Flow Files (04-08)

### Task 1: Home Page Flow

**Files:**
- Create: `flutter_app/.maestro/04_home_page.yaml`

- [ ] **Step 1: Create 04_home_page.yaml**

Prerequisites: app must be logged in with an existing couple space. The flow assumes the user is already authenticated and has a couple (run after 01+02 flows succeed).

```yaml
appId: com.love4lili.love4lili_flutter
---
- launchApp
- waitForAnimationToEnd:
    timeout: 10000

# If on login page, this flow needs pre-auth — skip gracefully
- runFlow:
    when:
      visible: "登录"
    commands:
      - assertVisible: "登录"
      - skip: true  # Not logged in, skip this flow

# Verify home page loaded
- assertVisible: "Love4Lili"
- assertVisible: "记录约会"
- assertVisible: "愿望清单"
- assertVisible: "相册"
- takeScreenshot: home_page_loaded

# Tap "查看全部" to see all records (if exists)
- runFlow:
    when:
      visible: "查看全部"
    commands:
      - tapOn: "查看全部"
      - waitForAnimationToEnd:
          timeout: 5000
      - assertVisible: "记录"
      - pressBack

# Navigate to records via bottom nav
- tapOn: "记录"
- waitForAnimationToEnd:
    timeout: 5000
- assertVisible: "搜索记录标题、地点、描述..."
- takeScreenshot: records_page_loaded

# Navigate to gallery via bottom nav
- tapOn: "相册"
- waitForAnimationToEnd:
    timeout: 5000
- takeScreenshot: gallery_page_loaded

# Navigate to profile via bottom nav
- tapOn: "我的"
- waitForAnimationToEnd:
    timeout: 5000
- assertVisible: "设置"
- takeScreenshot: profile_page_loaded

# Navigate back to home
- tapOn: "首页"
- waitForAnimationToEnd:
    timeout: 5000
- assertVisible: "记录约会"
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/.maestro/04_home_page.yaml
git commit -m "test: add Maestro home page flow"
```

---

### Task 2: Records Flow

**Files:**
- Create: `flutter_app/.maestro/05_records_flow.yaml`

- [ ] **Step 1: Create 05_records_flow.yaml**

```yaml
appId: com.love4lili.love4lili_flutter
---
- launchApp
- waitForAnimationToEnd:
    timeout: 10000

# Navigate to records
- runFlow:
    when:
      visible: "记录"
    commands:
      - tapOn: "记录"
- waitForAnimationToEnd:
    timeout: 5000

# Try to create a new record via home quick action
- tapOn: "首页"
- waitForAnimationToEnd:
    timeout: 5000

- runFlow:
    when:
      visible: "记录约会"
    commands:
      - tapOn: "记录约会"
      - waitForAnimationToEnd:
          timeout: 5000
      - takeScreenshot: record_edit_page

      # Fill record form
      - tapOn: "请输入标题"
      - inputText: "Maestro Test Record"
      - hideKeyboard

      - tapOn: "请输入地点"
      - inputText: "Shanghai"
      - hideKeyboard

      - takeScreenshot: record_form_filled

      # Try to save (may fail without mood selection)
      - tapOn: "保存"
      - waitForAnimationToEnd:
          timeout: 10000
      - takeScreenshot: record_save_result

      # Go back to records list
      - pressBack
      - waitForAnimationToEnd:
          timeout: 5000

# Verify records list
- tapOn: "记录"
- waitForAnimationToEnd:
    timeout: 5000
- takeScreenshot: records_list_result
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/.maestro/05_records_flow.yaml
git commit -m "test: add Maestro records flow"
```

---

### Task 3: Gallery Flow

**Files:**
- Create: `flutter_app/.maestro/06_gallery_flow.yaml`

- [ ] **Step 1: Create 06_gallery_flow.yaml**

```yaml
appId: com.love4lili.love4lili_flutter
---
- launchApp
- waitForAnimationToEnd:
    timeout: 10000

# Navigate to gallery
- runFlow:
    when:
      visible: "相册"
    commands:
      - tapOn: "相册"
- waitForAnimationToEnd:
    timeout: 5000
- takeScreenshot: gallery_page

# Switch between grid and list view
- runFlow:
    when:
      visible: "全部"
    commands:
      - assertVisible: "全部"
      - assertVisible: "照片"
      - assertVisible: "视频"

      # Filter by photos
      - tapOn: "照片"
      - waitForAnimationToEnd:
          timeout: 3000
      - takeScreenshot: gallery_photos_filter

      # Filter by videos
      - tapOn: "视频"
      - waitForAnimationToEnd:
          timeout: 3000
      - takeScreenshot: gallery_videos_filter

      # Back to all
      - tapOn: "全部"
      - waitForAnimationToEnd:
          timeout: 3000
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/.maestro/06_gallery_flow.yaml
git commit -m "test: add Maestro gallery flow"
```

---

### Task 4: Settings Flow

**Files:**
- Create: `flutter_app/.maestro/07_settings_flow.yaml`

- [ ] **Step 1: Create 07_settings_flow.yaml**

```yaml
appId: com.love4lili.love4lili_flutter
---
- launchApp
- waitForAnimationToEnd:
    timeout: 10000

# Navigate to profile
- runFlow:
    when:
      visible: "我的"
    commands:
      - tapOn: "我的"
- waitForAnimationToEnd:
    timeout: 5000
- takeScreenshot: profile_page

# Navigate to settings
- tapOn: "设置"
- waitForAnimationToEnd:
    timeout: 5000
- takeScreenshot: settings_page

# Verify settings elements
- assertVisible: "昵称"
- assertVisible: "邮箱"
- takeScreenshot: settings_loaded

# Go back to profile
- pressBack
- waitForAnimationToEnd:
    timeout: 3000
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/.maestro/07_settings_flow.yaml
git commit -m "test: add Maestro settings flow"
```

---

### Task 5: Logout + Re-login Flow

**Files:**
- Create: `flutter_app/.maestro/08_logout_relogin.yaml`

- [ ] **Step 1: Create 08_logout_relogin.yaml**

```yaml
appId: com.love4lili.love4lili_flutter
---
- launchApp
- waitForAnimationToEnd:
    timeout: 10000

# Navigate to profile
- runFlow:
    when:
      visible: "我的"
    commands:
      - tapOn: "我的"
      - waitForAnimationToEnd:
          timeout: 5000

      # Tap logout
      - tapOn: "退出登录"
      - waitForAnimationToEnd:
          timeout: 3000

      # Confirm logout in dialog
      - tapOn: "退出"
      - waitForAnimationToEnd:
          timeout: 5000

      # Should be back on login page
      - assertVisible: "登录"
      - assertVisible: "没有账号？"
      - takeScreenshot: logout_success

      # Re-login with test credentials
      - tapOn: "请输入邮箱地址"
      - inputText: "maestro_test_2026@example.com"
      - tapOn: "请输入密码"
      - inputText: "Test123456"
      - hideKeyboard

      - tapOn: "登录"
      - waitForAnimationToEnd:
          timeout: 15000
      - takeScreenshot: relogin_result
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/.maestro/08_logout_relogin.yaml
git commit -m "test: add Maestro logout and re-login flow"
```

---

## Chunk 2: Bug Hunt Orchestrator Script

### Task 6: bug_hunt.sh — Main Script

**Files:**
- Create: `flutter_app/scripts/bug_hunt.sh`
- Modify: `flutter_app/.gitignore`

- [ ] **Step 1: Add bug_reports/ to .gitignore**

Append to existing `.gitignore`:

```
# Bug hunting outputs
bug_reports/
```

- [ ] **Step 2: Create bug_hunt.sh**

```bash
#!/usr/bin/env bash
# ============================================================
# Bug Hunt — Automated Bug Finding for Flutter App
# Phase 1: Structured traversal via Maestro
# ============================================================
#
# Usage:
#   ./scripts/bug_hunt.sh                     # Run all flows
#   ./scripts/bug_hunt.sh --flow=02           # Run specific flow
#   ./scripts/bug_hunt.sh --phase=1           # Explicitly run Phase 1
#   ./scripts/bug_hunt.sh --skip-pass         # Don't take screenshots on pass
#
# Exit codes:
#   0  All flows passed
#   1  One or more flows failed
#   2  Emulator not connected
#   3  Maestro not found
# ============================================================

set -euo pipefail

# --- Config ---
APP_ID="com.love4lili.love4lili_flutter"
EMU_ID="${EMU_ID:-emulator-5554}"
MAESTRO_BIN="${HOME}/.maestro/bin/maestro"
MAESTRO_DIR="."
BUG_REPORT_DIR="bug_reports/$(date +%Y-%m-%d)"
SCREENSHOT_DIR="/tmp/maestro_bug_hunt"
SKIP_PASS_SCREENSHOTS=false
SPECIFIC_FLOW=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --flow=*)  SPECIFIC_FLOW="${1#*=}" ;;
        --phase=*) ;;  # Only phase 1 for now
        --skip-pass) SKIP_PASS_SCREENSHOTS=true ;;
        --help|-h)
            echo "Usage: $0 [--flow=NN] [--skip-pass]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# --- Pre-flight ---
check_prerequisites() {
    if [[ ! -x "$MAESTRO_BIN" ]]; then
        echo "[FATAL] Maestro not found at $MAESTRO_BIN"
        echo "  Install: curl -Ls https://get.maestro.mobile.dev | bash"
        exit 3
    fi

    export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
    if ! adb devices 2>/dev/null | grep -q "${EMU_ID}.*device"; then
        echo "[FATAL] Emulator $EMU_ID not connected"
        exit 2
    fi

    if ! adb shell pidof "$APP_ID" >/dev/null 2>&1; then
        echo "[WARN] App $APP_ID is not running on emulator"
        echo "  Start: cd flutter_app && flutter run -d $EMU_ID"
        exit 2
    fi

    mkdir -p "$BUG_REPORT_DIR" "$SCREENSHOT_DIR"
    echo "[INFO] Prerequisites OK"
    echo "[INFO] Bug reports: $BUG_REPORT_DIR"
}

# --- Run a single flow ---
# Args: $1 = flow file path, $2 = flow number
run_flow() {
    local flow_file="$1"
    local flow_num="$2"
    local flow_name
    flow_name=$(basename "$flow_file" .yaml)

    echo ""
    echo "=========================================="
    echo "  [$flow_num] $flow_name"
    echo "=========================================="

    # Clear logcat before this flow
    adb logcat -c

    # Run Maestro
    local exit_code=0
    "$MAESTRO_BIN" test "$flow_file" \
        --no-ansi \
        2>&1 | tee "/tmp/maestro_output_${flow_num}.txt" \
        || exit_code=$?

    # Capture logcat regardless of pass/fail
    local logcat_file="$SCREENSHOT_DIR/${flow_name}_logcat.txt"
    adb logcat -d > "$logcat_file" 2>/dev/null

    if [[ $exit_code -eq 0 ]]; then
        echo "[PASS] $flow_name"
        if [[ "$SKIP_PASS_SCREENSHOTS" == "false" ]]; then
            adb shell screencap -p /sdcard/screen.png 2>/dev/null
            adb pull /sdcard/screen.png "$SCREENSHOT_DIR/${flow_name}_pass.png" 2>/dev/null
        fi
        return 0
    else
        echo "[FAIL] $flow_name (exit code: $exit_code)"

        # Save evidence
        local bug_dir="${BUG_REPORT_DIR}/${flow_num}_${flow_name}"
        mkdir -p "$bug_dir"

        # Screenshot
        adb shell screencap -p /sdcard/screen.png 2>/dev/null
        adb pull /sdcard/screen.png "$bug_dir/screenshot.png" 2>/dev/null

        # Logcat (Flutter only)
        grep -E "flutter|Flutter|dart|Dart" "$logcat_file" 2>/dev/null \
            | grep -i -E "Exception|Error|FATAL|crash|══|type '.*' is not" \
            > "$bug_dir/logcat_errors.txt" 2>/dev/null || true

        # Full logcat
        cp "$logcat_file" "$bug_dir/logcat_full.txt"

        # Maestro output
        cp "/tmp/maestro_output_${flow_num}.txt" "$bug_dir/maestro_output.txt"

        # Generate description
        local error_summary=""
        if [[ -s "$bug_dir/logcat_errors.txt" ]]; then
            error_summary=$(head -5 "$bug_dir/logcat_errors.txt")
        else
            error_summary="No Flutter errors in logcat. Check maestro_output.txt for assertion failures."
        fi

        cat > "$bug_dir/description.md" <<EOF
# Bug: $flow_name

**Flow file:** $flow_file
**Time:** $(date '+%Y-%m-%d %H:%M:%S')
**Exit code:** $exit_code

## Error Summary
$error_summary

## Files
- screenshot.png — Screen at time of failure
- logcat_errors.txt — Flutter errors only
- logcat_full.txt — Full system logcat
- maestro_output.txt — Maestro test output
EOF

        echo "[BUG] Evidence saved to $bug_dir/"
        return 1
    fi
}

# --- Main ---
main() {
    check_prerequisites

    local passed=0
    local failed=0
    local failed_flows=()

    # Collect flow files
    local flows=()
    if [[ -n "$SPECIFIC_FLOW" ]]; then
        flows=("$MAESTRO_DIR/${SPECIFIC_FLOW}"*.yaml)
    else
        flows=($(ls "$MAESTRO_DIR"/[0-9]*.yaml 2>/dev/null | sort))
    fi

    if [[ ${#flows[@]} -eq 0 ]]; then
        echo "[FATAL] No flow files found in $MAESTRO_DIR"
        exit 1
    fi

    echo "[INFO] Running ${#flows[@]} flows..."

    local flow_num=1
    for flow in "${flows[@]}"; do
        if run_flow "$flow" "$flow_num"; then
            ((passed++))
        else
            ((failed++))
            failed_flows+=("$(basename "$flow")")
        fi
        ((flow_num++))
    done

    # Summary
    echo ""
    echo "=========================================="
    echo "  BUG HUNT RESULTS"
    echo "=========================================="
    echo "  Passed:  $passed"
    echo "  Failed:  $failed"
    echo "  Total:   $((passed + failed))"
    echo ""

    if [[ ${#failed_flows[@]} -gt 0 ]]; then
        echo "  Failed flows:"
        for f in "${failed_flows[@]}"; do
            echo "    ✗ $f"
        done
        echo ""
        echo "  Bug reports: $BUG_REPORT_DIR/"
    fi

    echo "=========================================="

    [[ $failed -eq 0 ]]
}

main "$@"
```

- [ ] **Step 3: Make executable and test syntax**

```bash
chmod +x flutter_app/scripts/bug_hunt.sh
bash -n flutter_app/scripts/bug_hunt.sh  # syntax check
```

Expected: no output (syntax OK)

- [ ] **Step 4: Commit**

```bash
git add flutter_app/scripts/bug_hunt.sh flutter_app/.gitignore flutter_app/bug_reports/.gitkeep
git commit -m "feat: add bug hunt orchestrator script

- bug_hunt.sh runs all Maestro flows and collects evidence on failure
- Saves screenshots, logcat, and descriptions to bug_reports/
- Supports --flow=NN for single flow, --skip-pass for speed"
```

---

## Chunk 3: Integration Test + Documentation

### Task 7: End-to-end Validation

**Files:** None (testing only)

- [ ] **Step 1: Ensure emulator + app are running**

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
adb devices  # Should show emulator-5554
adb shell pidof com.love4lili.love4lili_flutter  # Should return PID
```

If app not running: `cd flutter_app && flutter run -d emulator-5554`

- [ ] **Step 2: Run a single flow to validate Maestro setup**

```bash
cd flutter_app
export PATH="$PATH:$HOME/.maestro/bin:$HOME/Library/Android/sdk/platform-tools"
maestro test .maestro/01_register_and_login.yaml --no-ansi
```

Expected: Flow runs, passes or fails with clear output.

- [ ] **Step 3: Run bug_hunt.sh**

```bash
cd flutter_app
./scripts/bug_hunt.sh --skip-pass
```

Expected: All flows run, summary printed, any failures saved to `bug_reports/`.

- [ ] **Step 4: Review results**

If bugs found:
```bash
ls bug_reports/$(date +%Y-%m-%d)/
cat bug_reports/$(date +%Y-%m-%d)/*/description.md
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: validate bug hunt flows and fix any issues"
```

---

### Task 8: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add bug hunting section to CLAUDE.md**

Append to the Flutter E2E testing section:

```markdown
### Bug Hunting（自动化 Bug 发现）

```bash
cd flutter_app

# 运行所有 Maestro flow，自动收集 bug 证据
./scripts/bug_hunt.sh

# 只跑指定 flow
./scripts/bug_hunt.sh --flow=02

# 跳过成功截图（更快）
./scripts/bug_hunt.sh --skip-pass
```

Bug 证据输出到 `flutter_app/bug_reports/YYYY-MM-DD/`，包含截图、logcat 和描述。
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add bug hunting instructions to CLAUDE.md"
```
