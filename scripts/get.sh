#!/usr/bin/env bash
# get.sh: Sync ~/.claude (effective config) to git repo
# Usage: ./scripts/get.sh [--dry-run]

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$HOME/.claude"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && info "Dry-run mode enabled"

# ── Pre-flight checks ──────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  error "jq is required to process settings.json (brew install jq)"
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  error "Source directory not found: $SOURCE_DIR"
  exit 1
fi

# ── rsync helper ───────────────────────────────────────────────────────────────
do_rsync() {
  local src="$1" dst="$2"
  local flags=(-av --delete --exclude='*.log' --exclude='.DS_Store')

  if $DRY_RUN; then
    rsync "${flags[@]}" --dry-run "$src" "$dst"
  else
    rsync "${flags[@]}" "$src" "$dst"
  fi
}

# ── 1. CLAUDE.md ───────────────────────────────────────────────────────────────
if [[ -f "$SOURCE_DIR/CLAUDE.md" ]]; then
  info "Sync CLAUDE.md..."
  $DRY_RUN || cp "$SOURCE_DIR/CLAUDE.md" "$REPO_DIR/CLAUDE.md"
else
  warn "CLAUDE.md not found in $SOURCE_DIR, skipped."
fi

# ── 2. settings.json: strip secrets (env field) ────────────────────────────────
if [[ -f "$SOURCE_DIR/settings.json" ]]; then
  info "Sync settings.json (secrets stripped)..."

  # Validate JSON is readable
  if ! jq empty "$SOURCE_DIR/settings.json" 2>/dev/null; then
    error "settings.json is not valid JSON. Aborting."
    exit 1
  fi

  if ! $DRY_RUN; then
    # Remove "env" field (may contain API keys)
    jq 'del(.env)' "$SOURCE_DIR/settings.json" > "$REPO_DIR/settings.json"
    info "  -> .env field removed from versioned settings.json"
  fi

  # Local backup of secrets (outside repo, gitignored)
  if jq -e '.env' "$SOURCE_DIR/settings.json" &>/dev/null; then
    warn "Environment variables found in settings.json"
    if ! $DRY_RUN; then
      jq '{env: .env}' "$SOURCE_DIR/settings.json" > "$REPO_DIR/settings.secrets.json"
      info "  -> Saved to settings.secrets.json (gitignored)"
    fi
  fi
else
  warn "settings.json not found in $SOURCE_DIR, skipped."
fi

# ── 3. Hooks ───────────────────────────────────────────────────────────────────
if [[ -d "$SOURCE_DIR/hooks" ]]; then
  info "Sync hooks/..."
  $DRY_RUN || mkdir -p "$REPO_DIR/hooks"
  do_rsync "$SOURCE_DIR/hooks/" "$REPO_DIR/hooks/"
else
  info "No hooks/ directory found."
fi

# ── 4. Commands (custom slash commands) ────────────────────────────────────────
if [[ -d "$SOURCE_DIR/commands" ]]; then
  info "Sync commands/..."
  $DRY_RUN || mkdir -p "$REPO_DIR/commands"
  do_rsync "$SOURCE_DIR/commands/" "$REPO_DIR/commands/"
else
  info "No commands/ directory found."
fi

info "get.sh done."
