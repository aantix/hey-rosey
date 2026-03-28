#!/bin/sh

# Rosey Test Suite
# She didn't ask to be tested. But here we are.
#
# Usage: ./test.sh [test_name]
#   Run all tests:    ./test.sh
#   Run one test:     ./test.sh calendar
#
# Available tests: dependencies, calendar, scheduler, chrome, imessage, osascript

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="/tmp/rosey-tests"
PASSED=0
FAILED=0
SKIPPED=0
RESULTS=""

mkdir -p "$LOG_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

run_test() {
    TEST_NAME="$1"
    TEST_DESC="$2"
    TEST_PROMPT="$3"
    LOG_FILE="$LOG_DIR/rosey-test-${TEST_NAME}.log"

    printf "${BOLD}Testing: ${TEST_DESC}${NC} ... "

    claude -p "$TEST_PROMPT" --dangerously-skip-permissions > "$LOG_FILE" 2>&1
    EXIT_CODE=$?

    # Check for PASS/FAIL in output
    if [ $EXIT_CODE -ne 0 ]; then
        printf "${RED}FAIL${NC} (claude exited with code $EXIT_CODE)\n"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}\n  ${RED}FAIL${NC}  ${TEST_DESC} (see $LOG_FILE)"
        return 1
    elif grep -q "TEST_RESULT:PASS" "$LOG_FILE"; then
        printf "${GREEN}PASS${NC}\n"
        PASSED=$((PASSED + 1))
        RESULTS="${RESULTS}\n  ${GREEN}PASS${NC}  ${TEST_DESC}"
        return 0
    elif grep -q "TEST_RESULT:SKIP" "$LOG_FILE"; then
        printf "${YELLOW}SKIP${NC}\n"
        SKIPPED=$((SKIPPED + 1))
        REASON=$(grep "TEST_RESULT:SKIP" "$LOG_FILE" | head -1 | sed 's/.*TEST_RESULT:SKIP//')
        RESULTS="${RESULTS}\n  ${YELLOW}SKIP${NC}  ${TEST_DESC}${REASON}"
        return 0
    else
        printf "${RED}FAIL${NC} (no TEST_RESULT found in output)\n"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}\n  ${RED}FAIL${NC}  ${TEST_DESC} (see $LOG_FILE)"
        return 1
    fi
}

# ─────────────────────────────────────────────
# Test: Dependencies
# ─────────────────────────────────────────────
test_dependencies() {
    run_test "dependencies" "Dependencies installed" "
You are running a test for the Rosey chatbot system. Check that the following dependencies are installed and working:

1. Check that brew is installed: command -v brew
2. Check that icalBuddy is installed: command -v icalBuddy
3. Check that jq is installed: command -v jq

For each one, run the command and verify it returns a path.

If ALL dependencies are found, output exactly: TEST_RESULT:PASS
If any are missing, output exactly: TEST_RESULT:FAIL and list which ones are missing.
Do not install anything. Just check.
"
}

# ─────────────────────────────────────────────
# Test: Plugins
# ─────────────────────────────────────────────
test_plugins() {
    run_test "plugins" "Claude Code plugins installed" "
You are running a test for the Rosey chatbot system. Check that the required Claude Code plugins are available:

1. Check if the iMessage channel plugin is installed by looking for it in the plugin list or config
2. Check if the scheduler plugin is installed by looking for it in the plugin list or config

You can check by running: claude plugins list, or by looking in ~/.claude/plugins/ or similar config locations.

If both plugins are found, output exactly: TEST_RESULT:PASS
If any are missing, output exactly: TEST_RESULT:FAIL and list which ones are missing.
If you cannot determine plugin status, output: TEST_RESULT:SKIP - unable to verify plugin installation
"
}

# ─────────────────────────────────────────────
# Test: Calendar - Add Event
# ─────────────────────────────────────────────
test_calendar() {
    run_test "calendar" "Calendar add/read/delete event" "
You are running a test for the Rosey chatbot system. Test calendar integration by performing these steps IN ORDER:

1. CREATE a test calendar event using osascript:
   - Title: 'ROSEY_TEST_EVENT_12345'
   - Date: tomorrow at 12:00 PM
   - Calendar: use the default calendar
   - Use this AppleScript via osascript to create it:
     tell application \"Calendar\"
       tell calendar 1
         set newEvent to make new event with properties {summary:\"ROSEY_TEST_EVENT_12345\", start date:(current date) + 1 * days, end date:(current date) + 1 * days + 1 * hours}
       end tell
     end tell

2. VERIFY the event exists by running:
   icalBuddy -n eventsToday+7
   Look for 'ROSEY_TEST_EVENT_12345' in the output.

3. DELETE the test event using osascript:
   tell application \"Calendar\"
     tell calendar 1
       set theEvents to (every event whose summary is \"ROSEY_TEST_EVENT_12345\")
       repeat with anEvent in theEvents
         delete anEvent
       end repeat
     end tell
   end tell

4. VERIFY the event is gone by running icalBuddy again.

If create, verify, delete, and re-verify all succeeded, output exactly: TEST_RESULT:PASS
If any step fails, output exactly: TEST_RESULT:FAIL and explain which step failed.
"
}

# ─────────────────────────────────────────────
# Test: Scheduler - Add/Remove Task
# ─────────────────────────────────────────────
test_scheduler() {
    run_test "scheduler" "Scheduler add/list/remove task" "
You are running a test for the Rosey chatbot system. Test the scheduler plugin by performing these steps IN ORDER:

1. CREATE a test scheduled task using /scheduler:schedule-add
   - Make it a one-time task scheduled far in the future (e.g., December 31, 2099 at noon)
   - The task prompt should be: 'echo ROSEY_SCHEDULER_TEST'
   - This ensures it never actually fires

2. LIST scheduled tasks using /scheduler:schedule-list
   - Verify the test task appears in the list

3. REMOVE the test task using /scheduler:schedule-remove
   - Delete the task you just created

4. LIST again to verify the task is gone

If create, verify, remove, and re-verify all succeeded, output exactly: TEST_RESULT:PASS
If the scheduler plugin is not available, output: TEST_RESULT:SKIP - scheduler plugin not installed
If any step fails, output exactly: TEST_RESULT:FAIL and explain which step failed.
"
}

# ─────────────────────────────────────────────
# Test: Chrome Extension
# ─────────────────────────────────────────────
test_chrome() {
    run_test "chrome" "Chrome extension can browse" "
You are running a test for the Rosey chatbot system. Test Chrome browser automation:

1. Use the Claude for Chrome extension to navigate to https://example.com
2. Read the page content
3. Verify the page contains the text 'Example Domain'

If you successfully loaded the page and found 'Example Domain', output exactly: TEST_RESULT:PASS
If the Chrome extension is not available, output: TEST_RESULT:SKIP - Chrome extension not available
If the page failed to load or content was wrong, output: TEST_RESULT:FAIL and explain what happened.
"
}

# ─────────────────────────────────────────────
# Test: osascript iMessage send
# ─────────────────────────────────────────────
test_osascript() {
    run_test "osascript" "osascript iMessage fallback available" "
You are running a test for the Rosey chatbot system. Verify that osascript can be used as an iMessage fallback:

1. Check that osascript is available: command -v osascript
2. Verify the Messages app exists: check that /System/Applications/Messages.app exists
3. Do NOT actually send a message. Just verify the tools are available.

If both osascript and Messages.app are present, output exactly: TEST_RESULT:PASS
If either is missing, output exactly: TEST_RESULT:FAIL and explain what's missing.
"
}

# ─────────────────────────────────────────────
# Test: CLAUDE.md exists and has required sections
# ─────────────────────────────────────────────
test_claude_md() {
    run_test "claude-md" "CLAUDE.md has required sections" "
You are running a test for the Rosey chatbot system. Verify that $SCRIPT_DIR/CLAUDE.md exists and contains the required sections:

1. Read $SCRIPT_DIR/CLAUDE.md
2. Check that it contains these sections (look for ## headings):
   - 'Your Family'
   - 'Personality'
   - 'Skylight'
   - 'Calendar and Events'
   - 'Groceries'
   - 'Guardrails'
   - 'Scheduled Jobs'
   - 'iMessage'

If the file exists and ALL sections are present, output exactly: TEST_RESULT:PASS
If the file is missing, output: TEST_RESULT:FAIL - CLAUDE.md not found
If any sections are missing, output: TEST_RESULT:FAIL and list the missing sections.
"
}

# ─────────────────────────────────────────────
# Test: Session ID persistence
# ─────────────────────────────────────────────
test_session_id() {
    run_test "session-id" "Session ID file is valid" "
You are running a test for the Rosey chatbot system. Verify the session ID file:

1. Check if $SCRIPT_DIR/rosey_conversation_id.txt exists
2. If it exists, read it and verify the content looks like a valid UUID (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
3. Verify the file contains exactly one line (no extra whitespace or newlines that could break --resume)

If the file exists and contains a valid UUID, output exactly: TEST_RESULT:PASS
If the file does not exist, output: TEST_RESULT:SKIP - no session ID yet (setup has not been run)
If the file exists but content is not a valid UUID, output: TEST_RESULT:FAIL and show the content.
"
}

# ─────────────────────────────────────────────
# Test: icalBuddy can read calendars
# ─────────────────────────────────────────────
test_calendar_access() {
    run_test "calendar-access" "icalBuddy can read calendars" "
You are running a test for the Rosey chatbot system. Verify calendar access:

1. Run: icalBuddy calendars
2. This should list available calendars. If it returns at least one calendar, access is working.
3. If it returns an error about permissions, calendar access has not been granted yet.

If at least one calendar is listed, output exactly: TEST_RESULT:PASS
If no calendars are returned or there's a permissions error, output: TEST_RESULT:FAIL - calendar access not granted. User needs to run icalBuddy once while sitting in front of the Mac to approve the permissions prompt.
"
}

# ─────────────────────────────────────────────
# Run tests
# ─────────────────────────────────────────────

echo ""
echo "================================================"
echo "  Rosey Test Suite"
echo "  She didn't ask to be tested."
echo "  But here we are."
echo "================================================"
echo ""

if [ -n "$1" ]; then
    # Run a specific test
    case "$1" in
        dependencies)    test_dependencies ;;
        plugins)         test_plugins ;;
        calendar)        test_calendar ;;
        scheduler)       test_scheduler ;;
        chrome)          test_chrome ;;
        osascript)       test_osascript ;;
        claude-md)       test_claude_md ;;
        session-id)      test_session_id ;;
        calendar-access) test_calendar_access ;;
        *)
            echo "Unknown test: $1"
            echo "Available: dependencies, plugins, calendar, scheduler, chrome, osascript, claude-md, session-id, calendar-access"
            exit 1
            ;;
    esac
else
    # Run all tests
    test_claude_md
    test_dependencies
    test_plugins
    test_osascript
    test_session_id
    test_calendar_access
    test_calendar
    test_scheduler
    test_chrome
fi

# Summary
echo ""
echo "================================================"
printf "  Results: ${GREEN}${PASSED} passed${NC}, ${RED}${FAILED} failed${NC}, ${YELLOW}${SKIPPED} skipped${NC}\n"
printf "${RESULTS}\n"
echo ""
echo "  Logs: $LOG_DIR/"
echo "================================================"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "Rosey is disappointed. But she's not surprised."
    exit 1
else
    echo "All tests passed. Rosey is impressed. She will not say this again."
    exit 0
fi
