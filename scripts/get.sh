#!/usr/bin/env bash
# get.sh — Sync ~/.claude (config effective) vers le repo git
# Usage : ./scripts/get.sh [--dry-run]

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$HOME/.claude"

# Couleurs
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && info "Mode dry-run activé"

# ── Vérifications préalables ───────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  error "jq est requis pour traiter settings.json (brew install jq)"
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  error "Dossier source introuvable : $SOURCE_DIR"
  exit 1
fi

# ── Fonction rsync ─────────────────────────────────────────────────────────────
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
  warn "CLAUDE.md introuvable dans $SOURCE_DIR, ignoré."
fi

# ── 2. settings.json — strip des secrets (champ "env") ────────────────────────
if [[ -f "$SOURCE_DIR/settings.json" ]]; then
  info "Sync settings.json (secrets stripés)..."

  # Valide que le JSON est lisible
  if ! jq empty "$SOURCE_DIR/settings.json" 2>/dev/null; then
    error "settings.json n'est pas un JSON valide. Abandon."
    exit 1
  fi

  if ! $DRY_RUN; then
    # Supprime le champ "env" (contient potentiellement des API keys)
    jq 'del(.env)' "$SOURCE_DIR/settings.json" > "$REPO_DIR/settings.json"
    info "  → Champ .env retiré du settings.json versionné"
  fi

  # Sauvegarde locale des secrets (hors repo, gitignorée)
  if jq -e '.env' "$SOURCE_DIR/settings.json" &>/dev/null; then
    warn "Des variables d'environnement existent dans settings.json"
    if ! $DRY_RUN; then
      jq '{env: .env}' "$SOURCE_DIR/settings.json" > "$REPO_DIR/settings.secrets.json"
      info "  → Sauvegardé dans settings.secrets.json (gitignored)"
    fi
  fi
else
  warn "settings.json introuvable dans $SOURCE_DIR, ignoré."
fi

# ── 3. Hooks ───────────────────────────────────────────────────────────────────
if [[ -d "$SOURCE_DIR/hooks" ]]; then
  info "Sync hooks/..."
  $DRY_RUN || mkdir -p "$REPO_DIR/hooks"
  do_rsync "$SOURCE_DIR/hooks/" "$REPO_DIR/hooks/"
else
  info "Pas de dossier hooks/ trouvé."
fi

# ── 4. Commands (slash commands custom) ────────────────────────────────────────
if [[ -d "$SOURCE_DIR/commands" ]]; then
  info "Sync commands/..."
  $DRY_RUN || mkdir -p "$REPO_DIR/commands"
  do_rsync "$SOURCE_DIR/commands/" "$REPO_DIR/commands/"
else
  info "Pas de dossier commands/ trouvé."
fi

info "get.sh terminé."
