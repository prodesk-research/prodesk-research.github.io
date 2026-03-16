#!/bin/bash
# Pro Desk — Evening Cron Script
# Runs at 4:31 PM Mon–Fri automatically

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCANNER_DIR="$HOME/Desktop/nifty_vrp"
REPO_DIR="$HOME/Desktop/prodesk-research"
LOG="$SCANNER_DIR/cron_log.txt"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "" >> "$LOG"
echo "[$TS] ═══ EVENING CRON STARTED ═══" >> "$LOG"

DAY=$(date +%u)
if [ "$DAY" -gt 5 ]; then
  echo "[$TS] Weekend — skipping" >> "$LOG"
  exit 0
fi

cd "$SCANNER_DIR"

# Evening deploy
/bin/bash "$REPO_DIR/auto_deploy.sh" evening >> "$LOG" 2>&1
echo "[$TS] Evening deploy done" >> "$LOG"

# Friday: also run weekly summary
if [ "$DAY" -eq 5 ]; then
  /bin/bash "$REPO_DIR/auto_deploy.sh" weekly >> "$LOG" 2>&1
  echo "[$TS] Weekly summary deploy done" >> "$LOG"
fi

echo "[$TS] ═══ EVENING CRON COMPLETE ═══" >> "$LOG"
