#!/usr/bin/env bash
# ============================================================
# Bug Hunt Orchestrator — Maestro Flow Runner
# Runs all Maestro flows from .maestro/ and collects evidence
# on failure (screenshots, logcat, descriptions).
# ============================================================
#
# Usage:
#   ./scripts/bug_hunt.sh [options]
#
# Options:
#   --flow=NN       Run only the flow matching [0-9]*NN*.yaml
#   --skip-pass     Do not take screenshots on passing flows
#
# Environment:
#   EMU_ID          Emulator serial (default: emulator-5554)
#   MAESTRO_BIN     Maestro binary path (default: ~/.maestro/bin/maestro)
#
# Exit codes:
#   0  All flows passed
#   1  One or more flows failed
#   2  Pre-flight check failed
# ============================================================

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAESTRO_DIR="$PROJECT_DIR/.maestro"
BUG_REPORTS_DIR="$PROJECT_DIR/bug_reports"

EMU_ID="${EMU_ID:-emulator-5554}"
MAESTRO_BIN="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"

# Ensure adb is on PATH
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

# Parse arguments
RUN_FLOW=""
SKIP_PASS=false

for arg in "$@"; do
    case "$arg" in
        --flow=*)
            RUN_FLOW="${arg#--flow=}"
            ;;
        --skip-pass)
            SKIP_PASS=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--flow=NN] [--skip-pass]"
            exit 2
            ;;
    esac
done

# --- Tracking ---
PASSED=()
FAILED=()

# ============================================================
# Pre-flight Checks
# ============================================================

preflight() {
    echo "=== Pre-flight Checks ==="

    # Check Maestro binary
    if [[ ! -x "$MAESTRO_BIN" ]]; then
        echo "[FAIL] Maestro not found or not executable: $MAESTRO_BIN"
        echo "  Install: curl -Ls https://get.maestro.mobile.dev | bash"
        exit 2
    fi
    echo "[OK] Maestro: $MAESTRO_BIN"

    # Check emulator connected
    if ! adb devices 2>/dev/null | grep -q "${EMU_ID}.*device"; then
        echo "[FAIL] Emulator $EMU_ID not connected"
        echo "  Run: \$HOME/Library/Android/sdk/emulator/emulator -avd <name> &"
        exit 2
    fi
    echo "[OK] Emulator: $EMU_ID"

    # Check Maestro flows directory
    if [[ ! -d "$MAESTRO_DIR" ]]; then
        echo "[FAIL] Maestro flows directory not found: $MAESTRO_DIR"
        exit 2
    fi
    echo "[OK] Flows directory: $MAESTRO_DIR"

    # Check at least one flow exists
    local flow_count
    flow_count=$(find "$MAESTRO_DIR" -maxdepth 1 -name '[0-9]*.yaml' | wc -l | tr -d ' ')
    if [[ "$flow_count" -eq 0 ]]; then
        echo "[FAIL] No Maestro flows found matching [0-9]*.yaml in $MAESTRO_DIR"
        exit 2
    fi
    echo "[OK] Found $flow_count flow(s)"

    echo ""
}

# ============================================================
# Collect Evidence on Failure
# ============================================================

collect_evidence() {
    local flow_file="$1"
    local flow_name="$2"
    local exit_code="$3"
    local maestro_output="$4"

    local today
    today=$(date +%Y-%m-%d)

    # Extract flow number prefix (e.g., "01" from "01_register_and_login.yaml")
    local flow_num
    flow_num=$(basename "$flow_file" | grep -oE '^[0-9]+' || echo "00")

    local evidence_dir="$BUG_REPORTS_DIR/$today/${flow_num}_${flow_name}"
    mkdir -p "$evidence_dir"

    echo "  Collecting evidence to $evidence_dir"

    # Screenshot from adb
    adb -s "$EMU_ID" shell screencap -p /sdcard/screen.png 2>/dev/null || true
    adb -s "$EMU_ID" pull /sdcard/screen.png "$evidence_dir/screenshot.png" 2>/dev/null || true

    # Logcat: Flutter errors only
    adb -s "$EMU_ID" logcat -d 2>/dev/null \
        | grep -E "flutter|Flutter|dart|Dart" \
        | grep -E "Exception|Error|FATAL|crash|\u2550\u2550" \
        > "$evidence_dir/logcat_errors.txt" 2>/dev/null || true

    # Logcat: full dump
    adb -s "$EMU_ID" logcat -d 2>/dev/null > "$evidence_dir/logcat_full.txt" 2>/dev/null || true

    # Maestro output
    echo "$maestro_output" > "$evidence_dir/maestro_output.txt"

    # Auto-generated description
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local error_summary=""
    error_summary=$(echo "$maestro_output" | tail -30)

    cat > "$evidence_dir/description.md" <<DESC
# Bug Report: ${flow_name}

- **Flow**: $(basename "$flow_file")
- **Time**: ${timestamp}
- **Exit Code**: ${exit_code}

## Error Summary

\`\`\`
${error_summary}
\`\`\`

## Evidence Files

- \`screenshot.png\` — Device screenshot at time of failure
- \`logcat_errors.txt\` — Flutter/Dart errors from logcat
- \`logcat_full.txt\` — Full logcat dump
- \`maestro_output.txt\` — Full Maestro CLI output
DESC
}

# ============================================================
# Run a Single Flow
# ============================================================

run_flow() {
    local flow_file="$1"
    local flow_name
    flow_name=$(basename "$flow_file" .yaml | sed 's/^[0-9]*_//')

    echo "---"
    echo "Running: $(basename "$flow_file") ($flow_name)"
    echo ""

    # Clear logcat before each flow
    adb -s "$EMU_ID" logcat -c 2>/dev/null || true

    local maestro_output=""
    local exit_code=0

    # Run Maestro and capture output + exit code
    set +e
    maestro_output=$("$MAESTRO_BIN" test "$flow_file" --no-ansi 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
        echo "[PASS] $flow_name"
        PASSED+=("$flow_name")

        # Optionally take screenshot on pass
        if [[ "$SKIP_PASS" == "false" ]]; then
            local pass_dir="$BUG_REPORTS_DIR/passes"
            mkdir -p "$pass_dir"
            adb -s "$EMU_ID" shell screencap -p /sdcard/screen.png 2>/dev/null || true
            adb -s "$EMU_ID" pull /sdcard/screen.png "$pass_dir/${flow_name}.png" 2>/dev/null || true
        fi
    else
        echo "[FAIL] $flow_name (exit code: $exit_code)"
        FAILED+=("$flow_name")

        # Collect evidence
        collect_evidence "$flow_file" "$flow_name" "$exit_code" "$maestro_output"
    fi

    echo ""
}

# ============================================================
# Summary
# ============================================================

print_summary() {
    echo "=========================================="
    echo "  BUG HUNT SUMMARY"
    echo "=========================================="
    echo "  Passed: ${#PASSED[@]}"
    echo "  Failed: ${#FAILED[@]}"
    echo ""

    if [[ ${#PASSED[@]} -gt 0 ]]; then
        echo "  Passed flows:"
        for f in "${PASSED[@]}"; do
            echo "    [PASS] $f"
        done
        echo ""
    fi

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo "  Failed flows:"
        for f in "${FAILED[@]}"; do
            echo "    [FAIL] $f"
        done
        echo ""
    fi

    echo "=========================================="

    if [[ ${#FAILED[@]} -eq 0 ]]; then
        echo "[RESULT] ALL PASSED"
    else
        echo "[RESULT] ${#FAILED[@]} FAILED"
    fi

    echo "=========================================="

    [[ ${#FAILED[@]} -eq 0 ]]
}

# ============================================================
# Main
# ============================================================

main() {
    echo "Bug Hunt Orchestrator"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    preflight

    # Collect flow files
    local flows=()
    if [[ -n "$RUN_FLOW" ]]; then
        # Run specific flow matching the pattern
        local found=0
        for f in "$MAESTRO_DIR"/[0-9]*.yaml; do
            if [[ "$(basename "$f")" == *"${RUN_FLOW}"* ]]; then
                flows+=("$f")
                found=1
            fi
        done
        if [[ $found -eq 0 ]]; then
            echo "[FAIL] No flow matching '$RUN_FLOW' found in $MAESTRO_DIR"
            exit 2
        fi
    else
        # Run all numbered flows in sorted order
        while IFS= read -r -d '' f; do
            flows+=("$f")
        done < <(find "$MAESTRO_DIR" -maxdepth 1 -name '[0-9]*.yaml' -print0 | sort -z)
    fi

    echo "Will run ${#flows[@]} flow(s):"
    for f in "${flows[@]}"; do
        echo "  - $(basename "$f")"
    done
    echo ""

    # Execute each flow
    for f in "${flows[@]}"; do
        run_flow "$f"
    done

    # Print summary and exit
    print_summary
}

main "$@"
