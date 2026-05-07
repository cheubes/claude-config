#!/usr/bin/env bash
# deploy.sh — Déploie la config du repo vers ~/.claude
# Usage : ./scripts/deploy.sh [--dry-run] [--no-backup]

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/.claude"
BACKUP_BASE="$HOME/.claude-backups"

# Couleurs
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

$DRY_RUN && info "Mode dry-run activé — aucun fichier ne sera modifié"

# ── Vérifications préalables ───────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  error "jq est requis (brew install jq)"
  exit 1
fi

# ── git pull ───────────────────────────────────────────────────────────────────
section "Mise à jour du repo"
cd "$REPO_DIR"
if git ls-remote --exit-code --heads origin main &>/dev/null; then
  git pull
  info "Repo à jour."
else
  warn "Aucune branche 'main' sur le remote — pull ignoré (premier déploiement ?)."
fi

# ── Backup de la config actuelle ───────────────────────────────────────────────
section "Backup"
if $DO_BACKUP && [[ -d "$TARGET_DIR" ]]; then
  TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
  BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
  if ! $DRY_RUN; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$TARGET_DIR" "$BACKUP_DIR/claude"
    info "Backup créé : $BACKUP_DIR/claude"

    # Nettoyage : garde seulement les 10 derniers backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_BASE" | wc -l)
    if (( BACKUP_COUNT > 10 )); then
      ls -1t "$BACKUP_BASE" | tail -n +11 | while read -r old; do
        rm -rf "$BACKUP_BASE/$old"
        info "Ancien backup supprimé : $old"
      done
    fi
  else
    info "[dry-run] Backup simulé → $BACKUP_DIR/claude"
  fi
else
  $DO_BACKUP || warn "Backup désactivé (--no-backup)"
fi

# ── Fonction rsync ─────────────────────────────────────────────────────────────
do_rsync() {
  local src="$1" dst="$2"
  local flags=(-av --exclude='*.log' --exclude='.DS_Store')
  $DRY_RUN && flags+=(--dry-run)
  rsync "${flags[@]}" "$src" "$dst"
}

# ── Déploiement ────────────────────────────────────────────────────────────────
section "Déploiement"
$DRY_RUN || mkdir -p "$TARGET_DIR"

# 1. CLAUDE.md
if [[ -f "$REPO_DIR/CLAUDE.md" ]]; then
  info "Déploiement de CLAUDE.md..."
  $DRY_RUN || cp "$REPO_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
fi

# 2. settings.json — merge avec les secrets locaux
if [[ -f "$REPO_DIR/settings.json" ]]; then
  info "Déploiement de settings.json..."

  if [[ -f "$REPO_DIR/settings.secrets.json" ]]; then
    info "  → Fusion avec settings.secrets.json (secrets locaux)"
    if ! $DRY_RUN; then
      # Merge : le repo est la base, on ré-injecte les secrets par-dessus
      jq -s '.[0] * .[1]' \
        "$REPO_DIR/settings.json" \
        "$REPO_DIR/settings.secrets.json" \
        > "$TARGET_DIR/settings.json"
      info "  → settings.json fusionné avec succès"
    fi
  else
    warn "  Pas de settings.secrets.json trouvé — settings.json déployé sans le champ env"
    warn "  Si tu as des API keys, crée manuellement $REPO_DIR/settings.secrets.json"
    $DRY_RUN || cp "$REPO_DIR/settings.json" "$TARGET_DIR/settings.json"
  fi
fi

# 3. Hooks
if [[ -d "$REPO_DIR/hooks" ]]; then
  info "Déploiement de hooks/..."
  $DRY_RUN || mkdir -p "$TARGET_DIR/hooks"
  do_rsync "$REPO_DIR/hooks/" "$TARGET_DIR/hooks/"
  # Rend les scripts exécutables
  $DRY_RUN || find "$TARGET_DIR/hooks" -name "*.sh" -exec chmod +x {} \;
fi

# 4. Commands
if [[ -d "$REPO_DIR/commands" ]]; then
  info "Déploiement de commands/..."
  $DRY_RUN || mkdir -p "$TARGET_DIR/commands"
  do_rsync "$REPO_DIR/commands/" "$TARGET_DIR/commands/"
fi

section "Résultat"
if $DRY_RUN; then
  warn "Dry-run terminé — aucun fichier modifié."
else
  info "Config déployée dans $TARGET_DIR"
  info "Note : ~/.claude.json (session OAuth) n'a pas été touché."
fi
