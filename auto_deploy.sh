#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  PRO DESK — AUTO DEPLOY SCRIPT
#  Runs every morning after premarket_scanner.py
#  Generates fresh data.json → pushes to GitHub → site live in ~60s
#
#  Usage:
#    chmod +x auto_deploy.sh
#    ./auto_deploy.sh            → morning deploy
#    ./auto_deploy.sh evening    → evening deploy
#    ./auto_deploy.sh weekly     → weekly deploy
# ══════════════════════════════════════════════════════════════════════

set -e  # exit on any error

MODE="${1:-morning}"
SCANNER_DIR="$HOME/Desktop/nifty_vrp"
REPO_DIR="$HOME/Desktop/prodesk-research"
SITE_DIR="$REPO_DIR/site"
LOG_FILE="$SCANNER_DIR/deploy_log.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── Log helper ──────────────────────────────────────────────────────
log() {
  echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "═══════════════════════════════════════════════"
log "  PRO DESK AUTO DEPLOY — MODE: $MODE"
log "═══════════════════════════════════════════════"

# ── Step 1: Check repo exists ───────────────────────────────────────
if [ ! -d "$REPO_DIR/.git" ]; then
  log "ERROR: Repo not found at $REPO_DIR"
  log "       Run SETUP_GITHUB_PAGES.md first to clone your repo"
  exit 1
fi

# ── Step 2: Run premarket scanner (morning only) ────────────────────
if [ "$MODE" = "morning" ]; then
  log "Running premarket_scanner.py..."
  cd "$SCANNER_DIR"
  python3.11 premarket_scanner.py >> "$LOG_FILE" 2>&1 || {
    log "WARNING: premarket_scanner.py had errors — continuing with last data"
  }
fi

# ── Step 3: Generate data.json for the website ──────────────────────
log "Generating site data (data.json)..."
cd "$SCANNER_DIR"
python3.11 daily_brief_generator.py --mode "$MODE" --generate-site >> "$LOG_FILE" 2>&1 || {
  log "WARNING: data.json generation failed — using existing data.json"
}

# ── Step 4: Copy data.json to site directory ────────────────────────
if [ -f "$SCANNER_DIR/site/data.json" ]; then
  cp "$SCANNER_DIR/site/data.json" "$SITE_DIR/data.json"
  log "Copied data.json → $SITE_DIR/data.json"
elif [ -f "$SCANNER_DIR/data.json" ]; then
  cp "$SCANNER_DIR/data.json" "$SITE_DIR/data.json"
  log "Copied data.json from scanner dir"
else
  log "WARNING: No data.json found — site will show cached data"
fi

# ── Step 5: Git commit and push ─────────────────────────────────────
log "Pushing to GitHub..."
cd "$REPO_DIR"

git config user.name  "Pro Desk Bot"
git config user.email "prodesk@users.noreply.github.com"

git add site/data.json

# Only commit if there are changes
if git diff --staged --quiet; then
  log "No changes to deploy — data.json unchanged"
else
  COMMIT_MSG="[auto] $MODE brief — $(date '+%d %b %Y %H:%M IST')"
  git commit -m "$COMMIT_MSG"
  git push origin main

  log "✓ Pushed to GitHub — site will update in ~60 seconds"
  log "  URL: https://prodesk-research.github.io"
fi

# ── Step 6: Generate all platform files ─────────────────────────────
log "Generating platform outputs (Telegram/WhatsApp/X/Substack)..."
cd "$SCANNER_DIR"
python3.11 daily_brief_generator.py --mode "$MODE" >> "$LOG_FILE" 2>&1 || {
  log "WARNING: Platform file generation had errors"
}

log "───────────────────────────────────────────────"
log "DONE — $MODE deploy complete"
log "Site: https://prodesk-research.github.io"
log "Files: $SCANNER_DIR/daily_briefs/"
log "═══════════════════════════════════════════════"
