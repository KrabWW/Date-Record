#!/usr/bin/env bash
# ============================================================
# Flutter E2E Test Runner — Android Emulator (adb)
# Designed for Claude Code autonomous debug loops
# ============================================================
#
# Usage:
#   ./scripts/e2e_test.sh <scenario> [args...]
#   ./scripts/e2e_test.sh run                  # Full pipeline with retry + progression
#   ./scripts/e2e_test.sh run --max-retries 5  # Custom retry limit
#   ./scripts/e2e_test.sh login                # Single scenario
#   ./scripts/e2e_test.sh reset                # Clear logcat + screenshot
#
# Scenarios:
#   login           Test login flow
#   create-couple   Test couple space creation
#   home            Test home page loads without crash
#   add-record      Test creating a dating record
#   full            Run all scenarios in sequence (no retry)
#   run             Full pipeline with retry logic + auto progression
#   reset           Clear logcat, take fresh screenshot
#
# Options (env vars):
#   EMU_ID          Emulator serial (default: emulator-5554)
#   SCREENSHOT_DIR  Screenshot output dir (default: /tmp/flutter_e2e)
#   EMAIL           Login email (default: krab@qq.com)
#   PASSWORD        Login password (default: 123456)
#   MAX_RETRIES     Max retries per scenario (default: 3)
#
# Output format (parseable by Claude):
#   [STEP] N: description
#   [PASS] description
#   [FAIL] description → detail
#   [SCREENSHOT] /path/to/file.png
#   [LOGCAT] /path/to/file.txt
#   [ERRORS_FOUND] (followed by error lines)
#   [CONFIRMED] scenario_name — verified, moving to next
#   [RETRY] scenario_name attempt 2/3
#   [HUMAN_INTERVENTION_NEEDED] scenario_name — exceeded max retries
#   [RESULT] PASSED|FAILED|INTERVENTION_NEEDED
#
# Exit codes:
#   0  All steps passed
#   1  One or more steps failed
#   2  Timeout
#   3  Emulator not connected
#   4  Human intervention needed
# ============================================================

set -euo pipefail

# --- Configuration ---
EMU_ID="${EMU_ID:-emulator-5554}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp/flutter_e2e}"
EMAIL="${EMAIL:-krab@qq.com}"
PASSWORD="${PASSWORD:-123456}"
MAX_RETRIES="${MAX_RETRIES:-3}"

STEP_NUM=0
PASSED=()
FAILED=()
INTERVENTION_NEEDED=()

mkdir -p "$SCREENSHOT_DIR"

# ============================================================
# ADB Helpers
# ============================================================

adb_cmd() {
    adb -s "$EMU_ID" "$@"
}

tap() {
    local x=$1 y=$2
    adb_cmd shell input tap "$x" "$y"
}

type_text() {
    local text="$1"
    adb_cmd shell input text "$text"
}

type_email() {
    local email="$1"
    local local_part="${email%%@*}"
    local domain="${email#*@}"
    type_text "$local_part"
    sleep 0.1
    adb_cmd shell input keyevent 77  # @
    sleep 0.1
    type_text "$domain"
}

clear_field() {
    local count="${1:-20}"
    for ((i = 0; i < count; i++)); do
        adb_cmd shell input keyevent 67  # KEYCODE_DEL
        sleep 0.05
    done
}

press_enter() { adb_cmd shell input keyevent 66; }
press_back()  { adb_cmd shell input keyevent 4; }
scroll_down() { adb_cmd shell input keyevent 20; }
scroll_up()   { adb_cmd shell input keyevent 19; }

# ============================================================
# Observation Helpers
# ============================================================

screenshot() {
    local name="${1:-step_${STEP_NUM}}"
    local path="$SCREENSHOT_DIR/${name}.png"
    adb_cmd shell screencap -p /sdcard/screen.png 2>/dev/null
    adb_cmd pull /sdcard/screen.png "$path" 2>/dev/null
    echo "[SCREENSHOT] $path"
}

capture_logcat() {
    local name="${1:-logcat_${STEP_NUM}}"
    local path="$SCREENSHOT_DIR/${name}.txt"
    adb_cmd logcat -d > "$path" 2>/dev/null
    echo "[LOGCAT] $path"
}

check_logcat_errors() {
    local logcat_path="${1:-$SCREENSHOT_DIR/logcat_${STEP_NUM}.txt}"
    if [[ ! -f "$logcat_path" ]]; then
        return 0
    fi

    # Only look at Flutter/Dart process logs, skip all Android system noise
    local errors
    errors=$(grep -E "flutter|Flutter|dart|Dart" "$logcat_path" 2>/dev/null \
        | grep -i -E "Exception|Error|FATAL|crash|══|DioError|DioException|type '.*' is not|NoSuchMethodError|Null check" \
        | grep -v "error_count" \
        | tail -20)

    if [[ -n "$errors" ]]; then
        echo "[ERRORS_FOUND]"
        echo "$errors"
        return 1
    fi
    return 0
}

# ============================================================
# Step Tracking
# ============================================================

step() {
    STEP_NUM=$((STEP_NUM + 1))
    echo "[STEP] $STEP_NUM: $1"
}

pass() {
    echo "[PASS] $1"
    PASSED+=("$1")
}

fail() {
    local detail="${2:-}"
    if [[ -n "$detail" ]]; then
        echo "[FAIL] $1 → $detail"
    else
        echo "[FAIL] $1"
    fi
    FAILED+=("$1")
}

# ============================================================
# Pre-flight Checks
# ============================================================

check_emulator() {
    if ! adb devices 2>/dev/null | grep -q "${EMU_ID}.*device"; then
        echo "[FATAL] Emulator $EMU_ID not connected"
        echo "  Run: \$HOME/Library/Android/sdk/emulator/emulator -avd <name> &"
        exit 3
    fi
    echo "[INFO] Emulator $EMU_ID connected"
}

check_app_running() {
    local pid
    pid=$(adb_cmd shell pidof com.example.love4lili_flutter 2>/dev/null || true)
    if [[ -z "$pid" ]]; then
        echo "[WARN] Flutter app may not be running (no pidof match)"
        echo "  Start: cd flutter_app && flutter run -d $EMU_ID"
        return 1
    fi
    echo "[INFO] App running (pid: $pid)"
    return 0
}

# ============================================================
# Scenario Confirmation
# ============================================================
# After each scenario, verify it succeeded and decide whether to proceed.
# Confirmation strategy:
#   1. Check logcat for errors → any error = FAIL
#   2. Take a final screenshot for Claude to visually verify
#   3. Output [CONFIRMED] so the runner knows to move on
# ============================================================

confirm_scenario() {
    local scenario_name="$1"
    local logcat_file="$2"
    local screenshot_name="$3"

    step "Confirm scenario result: $scenario_name"
    sleep 2
    screenshot "$screenshot_name"
    capture_logcat "$logcat_file"

    if check_logcat_errors "$SCREENSHOT_DIR/$logcat_file.txt"; then
        echo "[CONFIRMED] $scenario_name"
        return 0
    else
        return 1
    fi
}

# ============================================================
# Scenario: Login
# ============================================================

scenario_login() {
    local email="${1:-$EMAIL}"
    local password="${2:-$PASSWORD}"

    echo ""
    echo "=========================================="
    echo "  SCENARIO: LOGIN"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Screenshot — login page"
    screenshot "login_01_page"

    step "Tap email field"
    tap 540 720
    sleep 1.0

    step "Clear & type email: $email"
    clear_field 20
    sleep 0.3
    type_email "$email"
    sleep 0.5

    step "Tap password field"
    tap 540 870
    sleep 1.0

    step "Clear & type password"
    clear_field 20
    sleep 0.3
    type_text "$password"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "login_02_filled"

    step "Tap login button"
    tap 540 1020
    echo "[INFO] Waiting 8s for API response..."
    sleep 8

    step "Check for errors during login"
    capture_logcat "login_logcat"
    if check_logcat_errors "$SCREENSHOT_DIR/login_logcat.txt"; then
        pass "No errors in logcat"
    else
        fail "Errors detected" "Review login_logcat.txt"
        return 1
    fi

    # Confirmation: wait for navigation, then verify
    sleep 3
    confirm_scenario "login" "login_confirm_logcat" "login_03_confirmed"
}

# ============================================================
# Scenario: Logout (used between login and re-login)
# ============================================================

scenario_logout() {
    echo ""
    echo "=========================================="
    echo "  SCENARIO: LOGOUT"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Screenshot — current page before logout"
    screenshot "logout_01_before"

    step "Tap profile/avatar area (top-right)"
    tap 980 120
    sleep 2

    step "Screenshot — profile/settings page"
    screenshot "logout_02_profile"

    step "Tap logout/退出登录 button"
    tap 540 1800
    sleep 3

    step "Screenshot — after logout"
    screenshot "logout_03_result"

    confirm_scenario "logout" "logout_confirm_logcat" "logout_04_confirmed"
}

# ============================================================
# Scenario: Create Couple Space
# ============================================================

scenario_create_couple() {
    local couple_name="${1:-Test Couple}"

    echo ""
    echo "=========================================="
    echo "  SCENARIO: CREATE COUPLE SPACE"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Screenshot — couple setup page"
    screenshot "couple_01_setup_page"

    step "Tap '创建新的情侣空间'"
    tap 540 920
    sleep 3

    step "Screenshot — create couple page"
    screenshot "couple_02_create_page"

    step "Tap couple name field"
    tap 540 680
    sleep 1.0

    step "Clear & type couple name: $couple_name"
    clear_field 20
    sleep 0.3
    adb_cmd shell input text "${couple_name// /%s}"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "couple_03_filled"

    step "Tap date picker field (anniversary)"
    tap 540 800
    sleep 2

    step "Confirm date selection"
    press_enter
    sleep 2

    step "Screenshot — after date selection"
    screenshot "couple_04_date_selected"

    step "Check logcat for date picker errors"
    capture_logcat "couple_date_logcat"
    if check_logcat_errors "$SCREENSHOT_DIR/couple_date_logcat.txt"; then
        pass "Date picker — no errors"
    else
        fail "Date picker error" "Review couple_date_logcat.txt and couple_04_date_selected.png"
        # Don't return — the date picker crash is a known issue, continue to see full state
    fi

    step "Tap '创建空间' button"
    tap 540 1050
    echo "[INFO] Waiting 8s for API..."
    sleep 8

    step "Screenshot — after submit"
    screenshot "couple_05_result"

    confirm_scenario "create-couple" "couple_confirm_logcat" "couple_06_confirmed"
}

# ============================================================
# Scenario: Join Couple Space (invalid code)
# ============================================================

scenario_join_couple() {
    echo ""
    echo "=========================================="
    echo "  SCENARIO: JOIN COUPLE SPACE (invalid code)"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Screenshot — couple setup page"
    screenshot "join_01_setup_page"

    step "Tap '加入伴侣的空间'"
    tap 540 1100
    sleep 3

    step "Screenshot — join couple page"
    screenshot "join_02_join_page"

    step "Tap invite code field"
    tap 540 680
    sleep 1.0

    step "Type invalid invite code"
    clear_field 20
    sleep 0.3
    type_text "INVALID1"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "join_03_filled"

    step "Tap '加入空间' button"
    tap 540 1050
    sleep 5

    step "Screenshot — after submit (should show error)"
    screenshot "join_04_result"

    confirm_scenario "join-couple" "join_confirm_logcat" "join_05_confirmed"
}

# ============================================================
# Scenario: Home Page
# ============================================================

scenario_home() {
    echo ""
    echo "=========================================="
    echo "  SCENARIO: HOME PAGE"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Press back to reach home"
    press_back
    sleep 3

    step "Screenshot — home page"
    screenshot "home_01_page"

    step "Wait for data loading"
    sleep 5

    step "Screenshot — after data load"
    screenshot "home_02_loaded"

    confirm_scenario "home" "home_confirm_logcat" "home_03_confirmed"

    step "Scroll down to check more content"
    scroll_down
    sleep 1
    screenshot "home_04_scrolled"

    pass "Home page scenario completed"
}

# ============================================================
# Scenario: Add Record
# ============================================================

scenario_add_record() {
    echo ""
    echo "=========================================="
    echo "  SCENARIO: ADD DATING RECORD"
    echo "=========================================="

    adb_cmd logcat -c
    sleep 0.5

    step "Tap '记录约会' quick action (left button on home)"
    tap 180 1450
    sleep 3

    step "Screenshot — record edit page"
    screenshot "record_01_edit_page"

    step "Tap title field"
    tap 540 400
    sleep 0.8

    step "Type record title"
    clear_field 20
    sleep 0.2
    adb_cmd shell input text "Test%20Date"
    sleep 0.3

    # Re-type properly
    clear_field 20
    sleep 0.2
    adb_cmd shell input text "Test Date"
    sleep 0.5

    step "Tap location field"
    tap 540 520
    sleep 0.8

    step "Type location"
    clear_field 20
    sleep 0.2
    adb_cmd shell input text "Shanghai"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "record_02_filled"

    step "Tap save button"
    tap 540 2100
    echo "[INFO] Waiting 8s for API..."
    sleep 8

    step "Screenshot — after save"
    screenshot "record_03_result"

    confirm_scenario "add-record" "record_confirm_logcat" "record_04_confirmed"
}

# ============================================================
# Scenario: Reset (utility)
# ============================================================

scenario_reset() {
    echo ""
    echo "=========================================="
    echo "  RESET: Clear logs, fresh screenshot"
    echo "=========================================="

    adb_cmd logcat -c
    echo "[INFO] Logcat cleared"

    sleep 1
    screenshot "reset_current"
    echo "[INFO] Fresh screenshot taken — review reset_current.png"
}

# ============================================================
# Pipeline Runner — retry + progression + human intervention
# ============================================================

# Run a single scenario with retry logic.
# Returns: 0 = passed, 1 = failed (after all retries), 2 = intervention needed
run_with_retry() {
    local scenario_name="$1"
    shift
    local attempt=0

    while ((attempt < MAX_RETRIES)); do
        attempt=$((attempt + 1))
        STEP_NUM=0  # reset step counter per attempt
        PASSED=()
        FAILED=()

        if ((attempt > 1)); then
            echo ""
            echo "[RETRY] $scenario_name — attempt $attempt/$MAX_RETRIES"
            # Brief pause before retry
            sleep 3
        fi

        # Run the scenario function
        if "scenario_${scenario_name}" "$@"; then
            echo ""
            echo "[SCENARIO_PASSED] $scenario_name (attempt $attempt/$MAX_RETRIES)"
            return 0
        fi

        echo ""
        echo "[SCENARIO_FAILED] $scenario_name (attempt $attempt/$MAX_RETRIES)"
    done

    # Exhausted all retries
    echo ""
    echo "[HUMAN_INTERVENTION_NEEDED] $scenario_name"
    echo "  Failed after $MAX_RETRIES attempts."
    echo "  Screenshots: $SCREENSHOT_DIR/*_confirmed.png, $SCREENSHOT_DIR/*_result.png"
    echo "  Logs: $SCREENSHOT_DIR/*_logcat.txt, $SCREENSHOT_DIR/*_confirm_logcat.txt"
    echo "  Action: Claude should read the screenshots and logs, diagnose the root cause,"
    echo "          fix the code, hot reload, then re-run this scenario manually."
    return 2
}

# Pipeline: run scenarios in order with retry + auto-progression
#
# Stage flow:
#   1. login          — 登录
#   2. logout         — 注销（验证认证闭环）
#   3. login          — 重新登录（验证再次登录）
#   4. create-couple  — 创建空间
#   5. join-couple    — 加入空间（无效邀请码）
#   6. home           — 首页加载
#
# Each stage: pass → auto-progress, fail → retry (up to MAX_RETRIES),
#              exhausted → [HUMAN_INTERVENTION_NEEDED] → STOP

run_pipeline() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  E2E PIPELINE — max retries: $MAX_RETRIES             ║"
    echo "╚══════════════════════════════════════════════╝"

    local all_passed=true
    local total_stages=6
    local stage_num=0

    # Define stages as: "func_name:args:label"
    # Empty args means no extra arguments
    local stages=(
        "login::1/$total_stages 登录"
        "logout::2/$total_stages 注销"
        "login::3/$total_stages 重新登录"
        "create_couple:Test Couple:4/$total_stages 创建空间"
        "join_couple::5/$total_stages 加入空间（无效邀请码）"
        "home::6/$total_stages 首页加载"
    )

    for stage_def in "${stages[@]}"; do
        local func_name="${stage_def%%:*}"
        local rest="${stage_def#*:}"
        local args="${rest%%:*}"
        local label="${rest#*:}"
        stage_num=$((stage_num + 1))

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  PIPELINE STAGE $label"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local result=0
        if [[ -n "$args" ]]; then
            run_with_retry "$func_name" "$args" || result=$?
        else
            run_with_retry "$func_name" || result=$?
        fi

        if ((result == 0)); then
            echo "[PROGRESS] $label confirmed → next stage"
        elif ((result == 2)); then
            echo "[PROGRESS] $label needs human intervention → STOPPING PIPELINE"
            INTERVENTION_NEEDED+=("$func_name")
            all_passed=false
            break
        else
            echo "[PROGRESS] $label failed → STOPPING PIPELINE"
            all_passed=false
            break
        fi
    done

    # Final summary
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  PIPELINE SUMMARY                            ║"
    echo "╚══════════════════════════════════════════════╝"

    if $all_passed; then
        echo "  [RESULT] ALL PASSED"
        return 0
    elif [[ ${#INTERVENTION_NEEDED[@]} -gt 0 ]]; then
        echo "  [RESULT] INTERVENTION_NEEDED"
        echo "  Blocked at: ${INTERVENTION_NEEDED[*]}"
        echo ""
        echo "  To resume after fixing:"
        echo "    # Fix the code, hot reload, then re-run full pipeline:"
        echo "    ./scripts/e2e_test.sh run"
        echo "    # or run just the blocked stage:"
        echo "    ./scripts/e2e_test.sh ${INTERVENTION_NEEDED[0]}"
        return 4
    else
        echo "  [RESULT] FAILED"
        return 1
    fi
}

# ============================================================
# Summary (for single-scenario mode)
# ============================================================

print_summary() {
    echo ""
    echo "=========================================="
    echo "  TEST SUMMARY"
    echo "=========================================="
    echo "  Passed: ${#PASSED[@]}"
    echo "  Failed: ${#FAILED[@]}"
    echo ""

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo "  Failures:"
        for f in "${FAILED[@]}"; do
            echo "    x $f"
        done
        echo ""
    fi

    echo "  Screenshots: $SCREENSHOT_DIR/"
    ls -1 "$SCREENSHOT_DIR"/*.png 2>/dev/null | while read -r f; do
        echo "    $(basename "$f")"
    done

    echo ""
    echo "=========================================="
    echo "[RESULT] $([[ ${#FAILED[@]} -eq 0 ]] && echo "PASSED" || echo "FAILED")"
    echo "=========================================="

    [[ ${#FAILED[@]} -eq 0 ]]
}

# ============================================================
# Main
# ============================================================

main() {
    local scenario="${1:-login}"

    check_emulator
    check_app_running || true  # warn but don't fail

    case "$scenario" in
        run)
            # Parse --max-retries flag
            shift 2>/dev/null || true
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --max-retries)
                        MAX_RETRIES="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            run_pipeline
            ;;
        login)
            scenario_login "${2:-}" "${3:-}"
            print_summary
            ;;
        logout)
            scenario_logout
            print_summary
            ;;
        create-couple)
            scenario_create_couple "${2:-}"
            print_summary
            ;;
        join-couple)
            scenario_join_couple
            print_summary
            ;;
        home)
            scenario_home
            print_summary
            ;;
        add-record)
            scenario_add_record
            print_summary
            ;;
        full)
            scenario_login "${2:-}" "${3:-}"
            scenario_create_couple "${4:-}"
            scenario_home
            print_summary
            ;;
        reset)
            scenario_reset
            return 0
            ;;
        *)
            echo "Usage: $0 <run|login|logout|create-couple|join-couple|home|add-record|full|reset>"
            echo ""
            echo "Commands:"
            echo "  run             Full pipeline with retry + auto-progression (recommended)"
            echo "  login           Test login flow"
            echo "  logout          Test logout flow"
            echo "  create-couple   Test couple space creation"
            echo "  join-couple     Test join couple (invalid code)"
            echo "  home            Test home page loads"
            echo "  add-record      Test creating a dating record"
            echo "  full            Run all scenarios sequentially (no retry)"
            echo "  reset           Clear logcat + fresh screenshot"
            echo ""
            echo "Environment variables:"
            echo "  EMU_ID=$EMU_ID"
            echo "  EMAIL=$EMAIL"
            echo "  PASSWORD=<hidden>"
            echo "  SCREENSHOT_DIR=$SCREENSHOT_DIR"
            echo "  MAX_RETRIES=$MAX_RETRIES"
            exit 1
            ;;
    esac
}

main "$@"
