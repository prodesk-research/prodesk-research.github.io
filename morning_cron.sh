#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  PRO DESK — MORNING CRON SCRIPT
#  This is the ONE script you add to Mac cron once.
#  It runs the full morning chain automatically.
#
#  REGISTER THIS SCRIPT:
#    Open Terminal and run:
#      crontab -e
#
#    Add these lines (press i to edit, then :wq to save in vim):
#      # Pro Desk morning brief — runs at 8:31 AM Mon-Fri
#      31 8 * * 1-5 /bin/bash $HOME/Desktop/prodesk-research/morning_cron.sh
#
#      # Pro Desk evening debrief — runs at 4:31 PM Mon-Fri
#      31 16 * * 1-5 /bin/bash $HOME/Desktop/prodesk-research/evening_cron.sh
#
#  IMPORTANT: Mac must be awake and connected to internet for cron to run.
#  Consider enabling "Prevent computer from sleeping automatically"
#  in System Preferences > Battery for trading days.
# ══════════════════════════════════════════════════════════════════════

# Ensure PATH has Python and git
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCANNER_DIR="$HOME/Desktop/nifty_vrp"
REPO_DIR="$HOME/Desktop/prodesk-research"
LOG="$SCANNER_DIR/cron_log.txt"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "" >> "$LOG"
echo "[$TS] ═══ MORNING CRON STARTED ═══" >> "$LOG"

# ── Check it's a trading day (Mon–Fri) ──────────────────────────────
DAY=$(date +%u)  # 1=Mon … 7=Sun
if [ "$DAY" -gt 5 ]; then
  echo "[$TS] Weekend — skipping" >> "$LOG"
  exit 0
fi

# ── Check for NSE holidays (optional — add known holidays here) ──────
TODAY=$(date '+%Y-%m-%d')
HOLIDAYS=(
  "2026-01-26"   # Republic Day
  "2026-03-17"   # Holi
  "2026-04-14"   # Ambedkar Jayanti
  "2026-08-15"   # Independence Day
  "2026-10-02"   # Gandhi Jayanti
  # Add more as needed
)
for h in "${HOLIDAYS[@]}"; do
  if [ "$TODAY" = "$h" ]; then
    echo "[$TS] NSE Holiday ($h) — skipping" >> "$LOG"
    exit 0
  fi
done

# ── Run the full morning chain ───────────────────────────────────────
echo "[$TS] Starting morning chain..." >> "$LOG"

# Step 1: Refresh Upstox token (if token refresh script exists)
if [ -f "$SCANNER_DIR/refresh_token.sh" ]; then
  /bin/bash "$SCANNER_DIR/refresh_token.sh" >> "$LOG" 2>&1
fi

# Step 2: Run premarket scanner
cd "$SCANNER_DIR"
python3.11 premarket_scanner.py >> "$LOG" 2>&1
echo "[$TS] premarket_scanner.py done" >> "$LOG"

# Step 3: Deploy to GitHub Pages
/bin/bash "$REPO_DIR/auto_deploy.sh" morning >> "$LOG" 2>&1
echo "[$TS] Morning deploy done" >> "$LOG"

echo "[$TS] ═══ MORNING CRON COMPLETE ═══" >> "$LOG"
