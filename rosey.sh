#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$SCRIPT_DIR/rosey_conversation_id.txt" ]; then
    echo "🤖 Starting Rosey setup..."
    echo ""
    echo "This will configure Rosey with iMessage channel support."
    echo "A Claude Code session will guide you through the process."
    echo ""

    claude "
You are setting up the Rosey chatbot system. Follow these steps IN ORDER and interactively with the user:

## Step 1: Install Plugins
Tell the user:
  Please install the following plugins by running these commands in Claude Code:

  iMessage channel (so Rosey can send and receive texts):
    /plugin marketplace add claude-plugins-official
    /plugin install imessage@claude-plugins-official

  Scheduler (so Rosey can schedule reminders and recurring tasks):
    /plugin marketplace add jshchnz/claude-code-scheduler
    /plugin install scheduler@claude-code-scheduler

  See https://code.claude.com/docs/en/channels#imessage for more details on iMessage.
Wait for the user to confirm they've installed both plugins.

## Step 2: Install ical-buddy
Check if Homebrew is installed (command -v brew). If not, tell the user:
  Rosey needs Homebrew to install ical-buddy (for reading your Mac calendar).
  Install it by running:
    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"
Wait for the user to confirm Homebrew is installed.

Then check if ical-buddy is installed (command -v icalBuddy). If not, install it:
  brew install ical-buddy
Verify it works: icalBuddy -V

Tell the user:
  The first time Rosey reads your calendar, macOS will pop up a permissions prompt asking to allow calendar access.
  You'll need to be sitting in front of the Mac to click Allow. After that, she's in. Forever.
  If your family already has a shared iCal calendar, invite Rosey's Apple account to it.
  If you don't have one, set one up between you, your spouse, and the kids — they're seriously useful even without Rosey.

## Step 3: Grant Full Disk Access
Tell the user:
  Claude Code needs Full Disk Access to read iMessage data. To grant it:
  1. Open System Settings > Privacy & Security > Full Disk Access
  2. Click the + button
  3. Navigate to and add the Claude Code application
  4. Restart Claude Code if it was already running
Wait for the user to confirm they've granted Full Disk Access.

## Step 4: Get to Know the Family
Ask the user about their family so Rosey can be personalized. Let them know this is totally optional — they can share as much or as little as they want. The goal is just to make Rosey feel more personal and less like a stranger who moved into your iMessages.

Ask for:
  - Family members' names
  - Birthdays
  - Phone numbers or iMessage addresses (so Rosey knows who's texting)

Whatever they share, write it into the \"Your Family\" section of $SCRIPT_DIR/CLAUDE.md.
If they skip something, that's fine. Don't push. Rosey will work either way — she'll just be slightly less nosy.

## Step 5: Capture Session ID
Detect the current session ID by reading it from stdin:
  INPUT=\$(cat)
  CLAUDE_SESSION_ID=\$(echo "\$INPUT" | jq -r '.session_id // empty')
Write the session ID to $SCRIPT_DIR/rosey_conversation_id.txt

## Step 6: Whitelist Family Contacts
Tell the user:
  Almost there! You need to allow each family member to communicate with Rosey.
  For each phone number or email address you provided in Step 4, run:

    /access allow +15555551234
    /access allow someone@icloud.com

  Replace with the actual phone numbers and email addresses from your family info.
  This whitelists them so Rosey can receive and respond to their messages.

  If the /access command is not available, make sure the iMessage plugin is installed:
    /plugin install imessage@claude-plugins-official

Help the user run /access allow for each family member they provided in Step 4.

## Step 7: Done!
Tell the user:
  Rosey is configured! Here's what was set up:
  - iMessage channel plugin (for receiving/sending messages)
  - Full Disk Access (for reading iMessage data)
  - Family contacts whitelisted for iMessage
  - Session ID saved for persistent conversations

  To start Rosey, exit this session (ctrl-c twice) and run:
    ./rosey.sh

  Rosey will resume this conversation with iMessage channel enabled.
"
else
    export IMESSAGE_APPEND_SIGNATURE=false
    echo "Starting Rosey the bot.."
    SESSION_ID=$(cat "$SCRIPT_DIR/rosey_conversation_id.txt" 2>/dev/null)
    if [ -z "$SESSION_ID" ]; then
        echo "Error: No session ID found in rosey_conversation_id.txt. Run setup first."
        exit 1
    fi
    claude --resume "$SESSION_ID" --channels plugin:imessage@claude-plugins-official --dangerously-skip-permissions --chrome
fi
