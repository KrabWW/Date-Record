#!/usr/bin/env bash
# ============================================================
# Flutter E2E Test Runner — Android Emulator (adb)
# Designed for Claude Code autonomous debug loops
# ============================================================
#
# Usage:
#   ./scripts/e2e_test.sh <scenario> [args...]
#
# Scenarios:
#   login           Test login flow (email, password)
#   create-couple   Test couple space creation
#   home            Test home page loads without crash
#   add-record      Test creating a dating record
#   full            Run all scenarios in sequence
#   reset           Clear logcat, take fresh screenshot
#
# Options (env vars):
#   EMU_ID          Emulator serial (default: emulator-5554)
#   SCREENSHOT_DIR  Screenshot output dir (default: /tmp/flutter_e2e)
#   EMAIL           Login email (default: krab@qq.com)
#   PASSWORD        Login password (default: 123456)
#
# Output format (parseable by Claude):
#   [STEP] N: description
#   [PASS] description
#   [FAIL] description → detail
#   [SCREENSHOT] /path/to/file.png
#   [LOGCAT] /path/to/file.txt
#   [ERRORS_FOUND] (followed by error lines)
#   [RESULT] PASSED|FAILED
#
# Exit codes:
#   0  All steps passed
#   1  One or more steps failed
#   2  Timeout
#   3  Emulator not connected
# ============================================================

set -euo pipefail

# --- Configuration ---
EMU_ID="${EMU_ID:-emulator-5554}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp/flutter_e2e}"
EMAIL="${EMAIL:-krab@qq.com}"
PASSWORD="${PASSWORD:-123456}"

STEP_NUM=0
PASSED=()
FAILED=()

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
    # adb input text: space/dot work, @ does NOT
    local text="$1"
    adb_cmd shell input text "$text"
}

type_email() {
    # Split at @, use keyevent 77 for @ symbol
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
    # Capture Flutter + system errors
    adb_cmd logcat -d > "$path" 2>/dev/null
    echo "[LOGCAT] $path"
}

check_logcat_errors() {
    local logcat_path="${1:-$SCREENSHOT_DIR/logcat_${STEP_NUM}.txt}"
    if [[ ! -f "$logcat_path" ]]; then
        return 0
    fi

    # Filter for Flutter exceptions and Android crashes
    # Look for: Exception, Error, FATAL, crash, ══ (Flutter red screen marker)
    local errors
    errors=$(grep -i -E "Exception|Error|FATAL|crash|══|DioError|DioException|type '.*' is not" "$logcat_path" 2>/dev/null \
        | grep -v "traceroute" \
        | grep -v "error_count" \
        | grep -v "CameraCapture" \
        | grep -v "InputDispatcher" \
        | tail -30)

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
    # Check if Flutter app process is alive on the emulator
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
# Scenario: Login
# ============================================================

scenario_login() {
    local email="${1:-$EMAIL}"
    local password="${2:-$PASSWORD}"

    echo ""
    echo "=========================================="
    echo "  SCENARIO: LOGIN"
    echo "=========================================="

    # Clear previous logs
    adb_cmd logcat -c
    sleep 0.5

    step "Screenshot — login page"
    screenshot "login_01_page"

    step "Tap email field"
    tap 540 750
    sleep 0.8

    step "Clear & type email: $email"
    clear_field 20
    sleep 0.2
    type_email "$email"
    sleep 0.5

    step "Tap password field"
    tap 540 860
    sleep 0.8

    step "Clear & type password"
    clear_field 20
    sleep 0.2
    type_text "$password"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "login_02_filled"

    step "Tap login button"
    tap 540 970
    echo "[INFO] Waiting 8s for API response..."
    sleep 8

    step "Screenshot — after login"
    screenshot "login_03_result"

    step "Capture logcat"
    capture_logcat "login_logcat"

    step "Check for errors"
    if check_logcat_errors "$SCREENSHOT_DIR/login_logcat.txt"; then
        pass "No errors in logcat"
    else
        fail "Errors detected" "Review login_logcat.txt and login_03_result.png"
        return 1
    fi

    step "Verify navigation"
    # Take another screenshot after potential redirect
    sleep 2
    screenshot "login_04_navigation"
    echo "[INFO] Review login_04_navigation.png to verify page transition"

    pass "Login scenario completed"
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
    tap 540 850
    sleep 3

    step "Screenshot — create couple page"
    screenshot "couple_02_create_page"

    step "Tap couple name field"
    tap 540 650
    sleep 0.8

    step "Clear & type couple name: $couple_name"
    clear_field 20
    sleep 0.2
    type_text "${couple_name// /%20}"  # adb text doesn't handle spaces well, use %20
    # Actually spaces work in adb input text
    sleep 0.3

    # Re-type with proper spaces
    clear_field 20
    sleep 0.2
    adb_cmd shell input text "$couple_name"
    sleep 0.5

    step "Screenshot — form filled"
    screenshot "couple_03_filled"

    step "Tap date picker field (anniversary)"
    tap 540 750
    sleep 2

    # Date picker may or may not appear. Press enter to confirm today.
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
    tap 540 950
    echo "[INFO] Waiting 8s for API..."
    sleep 8

    step "Screenshot — after submit"
    screenshot "couple_05_result"

    step "Capture logcat"
    capture_logcat "couple_submit_logcat"

    step "Check for errors"
    if check_logcat_errors "$SCREENSHOT_DIR/couple_submit_logcat.txt"; then
        pass "No errors after submit"
    else
        fail "Errors after submit" "Review couple_submit_logcat.txt and couple_05_result.png"
        return 1
    fi

    pass "Create couple scenario completed"
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

    step "Capture logcat"
    capture_logcat "home_logcat"

    step "Check for errors"
    if check_logcat_errors "$SCREENSHOT_DIR/home_logcat.txt"; then
        pass "No errors on home page"
    else
        fail "Home page errors" "Review home_logcat.txt and home_02_loaded.png"
        return 1
    fi

    step "Scroll down to check more content"
    scroll_down
    sleep 1
    screenshot "home_03_scrolled"

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
    adb_cmd shell input text "Test%20Date"  # "Test Date"
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

    step "Capture logcat"
    capture_logcat "record_logcat"

    step "Check for errors"
    if check_logcat_errors "$SCREENSHOT_DIR/record_logcat.txt"; then
        pass "No errors saving record"
    else
        fail "Record save errors" "Review record_logcat.txt and record_03_result.png"
        return 1
    fi

    pass "Add record scenario completed"
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
# Summary
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
        login)
            scenario_login "${2:-}" "${3:-}"
            ;;
        create-couple)
            scenario_create_couple "${2:-}"
            ;;
        home)
            scenario_home
            ;;
        add-record)
            scenario_add_record
            ;;
        full)
            scenario_login "${2:-}" "${3:-}"
            scenario_create_couple "${4:-}"
            scenario_home
            ;;
        reset)
            scenario_reset
            return 0
            ;;
        *)
            echo "Usage: $0 <login|create-couple|home|add-record|full|reset>"
            echo ""
            echo "Scenarios:"
            echo "  login           Test login flow"
            echo "  create-couple   Test couple space creation"
            echo "  home            Test home page loads"
            echo "  add-record      Test creating a dating record"
            echo "  full            Run all scenarios"
            echo "  reset           Clear logcat + fresh screenshot"
            echo ""
            echo "Environment variables:"
            echo "  EMU_ID=$EMU_ID"
            echo "  EMAIL=$EMAIL"
            echo "  PASSWORD=<hidden>"
            echo "  SCREENSHOT_DIR=$SCREENSHOT_DIR"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
