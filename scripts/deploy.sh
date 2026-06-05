#!/usr/bin/env bash
# deploy.sh: Deploy repo config to ~/.claude
# Usage: ./scripts/deploy.sh [--dry-run] [--no-backup]

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/.claude"
BACKUP_BASE="$HOME/.claude-backups"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${CYAN}══ $* ══${NC}"; }

DRY_RUN=false
DO_BACKUP=true
for arg in "${@:-}"; do
  [[ "$arg" == "--dry-run" ]]   && DRY_RUN=true
  [[ "$arg" == "--no-backup" ]] && DO_BACKUP=false
done

$DRY_RUN && info "Dry-run mode enabled: no files will be modified"

# ── Pre-flight checks ──────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  error "jq is required (brew install jq)"
  exit 1
fi

# ── git pull ───────────────────────────────────────────────────────────────────
section "Repo update"
cd "$REPO_DIR"
if git ls-remote --exit-code --heads origin main &>/dev/null; then
  git pull
  info "Repo up to date."
else
  warn "No 'main' branch on remote: pull skipped (first deployment?)."
fi

# ── Current config backup ──────────────────────────────────────────────────────
section "Backup"
if $DO_BACKUP && [[ -d "$TARGET_DIR" ]]; then
  TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
  BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
  if ! $DRY_RUN; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$TARGET_DIR" "$BACKUP_DIR/claude"
    info "Backup created: $BACKUP_DIR/claude"

    # Cleanup: keep only the last 10 backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_BASE" | wc -l)
    if (( BACKUP_COUNT > 10 )); then
      ls -1t "$BACKUP_BASE" | tail -n +11 | while read -r old; do
        rm -rf "$BACKUP_BASE/$old"
        info "Old backup removed: $old"
      done
    fi
  else
    info "[dry-run] Simulated backup: $BACKUP_DIR/claude"
  fi
else
  $DO_BACKUP || warn "Backup disabled (--no-backup)"
fi

# ── rsync helper ───────────────────────────────────────────────────────────────
do_rsync() {
  local src="$1" dst="$2"
  local flags=(-av --exclude='*.log' --exclude='.DS_Store')
  $DRY_RUN && flags+=(--dry-run)
  rsync "${flags[@]}" "$src" "$dst"
}

# ── Deployment ─────────────────────────────────────────────────────────────────
section "Deployment"
$DRY_RUN || mkdir -p "$TARGET_DIR"

# 1. CLAUDE.md
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  info "Deploying CLAUDE.md..."
  $DRY_RUN || cp "$REPO_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
fi

# 2. settings.json: merge with local secrets
if [[ -f "$REPO_DIR/settings.json" ]]; then
  info "Deploying settings.json..."

  if [[ -f "$REPO_DIR/settings.secrets.json" ]]; then
    info "  -> Merging with settings.secrets.json (local secrets)"
    if ! $DRY_RUN; then
      # Merge: repo is the base, secrets are injected on top
      jq -s '.[0] * .[1]' \
        "$REPO_DIR/settings.json" \
        "$REPO_DIR/settings.secrets.json" \
        > "$TARGET_DIR/settings.json"
      info "  -> settings.json merged successfully"
    fi
  else
    warn "  No settings.secrets.json found: settings.json deployed without env field"
    warn "  If you have API keys, create $REPO_DIR/settings.secrets.json manually"
    $DRY_RUN || cp "$REPO_DIR/settings.json" "$TARGET_DIR/settings.json"
  fi
fi

# 3. Hooks
if [[ -d "$REPO_DIR/hooks" ]]; then
  info "Deploying hooks/..."
  $DRY_RUN || mkdir -p "$TARGET_DIR/hooks"
  do_rsync "$REPO_DIR/hooks/" "$TARGET_DIR/hooks/"
  # Make scripts executable
  $DRY_RUN || find "$TARGET_DIR/hooks" -name "*.sh" -exec chmod +x {} \;
fi

# 4. Commands
if [[ -d "$REPO_DIR/commands" ]]; then
  info "Deploying commands/..."
  $DRY_RUN || mkdir -p "$TARGET_DIR/commands"
  do_rsync "$REPO_DIR/commands/" "$TARGET_DIR/commands/"
fi

section "Result"
if $DRY_RUN; then
  warn "Dry-run complete: no files modified."
else
  info "Config deployed to $TARGET_DIR"
  info "Note: ~/.claude.json (OAuth session) was not modified."
fi
