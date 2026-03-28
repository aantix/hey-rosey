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

## Step 0: Prerequisites
Before we start, confirm with the user:

1. **Apple Account for Rosey** — Ask: Are you signed into the Apple account that Rosey will use on this Mac?
   This needs to be a separate Apple account from your personal one, with iMessage active.
   If not, they need to sign in first before continuing. Rosey needs her own identity.

2. **Instacart** — Ask: If you want Rosey to shop for groceries, are you already logged into instacart.com in Chrome on this Mac?
   If they want grocery shopping, they need to be authenticated with Instacart before Rosey can shop.
   If they don't need groceries, skip this — it's optional.

Wait for the user to confirm before proceeding.

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

## Step 5: Skylight Calendar Frame (Optional)
Ask the user: Do you own a Skylight calendar frame?

If YES:
  Ask if they want Rosey to manage chores on the Skylight (posting and deleting tasks).
  If they do, ask them for:
    - Skylight username (email)
    - Skylight password
    - Frame ID
    - Category to post chores to (usually \"Chores\")

  Write these into the \"Skylight\" section of $SCRIPT_DIR/CLAUDE.md so Rosey knows how to connect.

If NO:
  That's fine. Skip it. Mention that Skylight is a kitchen display that shows chores, calendars, and family photos — worth looking into if they want the kids to see their chores the moment they walk in the door.

## Step 6: Capture Session ID
Detect the current session ID by reading it from stdin:
  INPUT=\$(cat)
  CLAUDE_SESSION_ID=\$(echo "\$INPUT" | jq -r '.session_id // empty')
Write the session ID to $SCRIPT_DIR/rosey_conversation_id.txt

## Step 7: Whitelist Family Contacts
Tell the user:
  Almost there! You need to allow each family member to communicate with Rosey.
  For each family member from Step 4, run /access allow with their phone number, iCloud address, or email address:

    /access allow +15555551234
    /access allow someone@icloud.com
    /access allow someone@email.com

  This whitelists them so Rosey can receive and respond to their messages.

  If the /access command is not available, make sure the iMessage plugin is installed:
    /plugin install imessage@claude-plugins-official

Help the user run /access allow for each family member they provided in Step 4.

## Step 8: Done!
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
