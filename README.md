# claude-config

Configuration personnelle pour Claude Code, versionnée et synchronisable.

## Structure

```
claude-config/
├── scripts/
│   ├── get.sh        # Sync ~/.claude → repo
│   └── deploy.sh     # Sync repo → ~/.claude
├── hooks/            # Hooks Claude Code (PostToolUse, PreToolUse…)
├── commands/         # Slash commands personnalisées
├── settings.json     # Config sans secrets
├── settings.secrets.json  # Secrets locaux — gitignored
├── CLAUDE.md         # Instructions globales
└── .gitignore
```

## Setup initial

```bash
# 1. Rends les scripts exécutables
chmod +x scripts/get.sh scripts/deploy.sh

# 2. Connecte au remote GitHub
git remote add origin git@github.com:TON_USER/claude-config.git

# 3. Premier sync
./scripts/get.sh
```

## Usage quotidien

```bash
# Sauvegarder la config courante
./scripts/get.sh

# Déployer sur une nouvelle machine
./scripts/deploy.sh

# Tester sans modifier de fichiers
./scripts/get.sh --dry-run
./scripts/deploy.sh --dry-run
```

## Secrets

Les variables d'environnement (API keys, tokens) dans `settings.json` sont
automatiquement extraites dans `settings.secrets.json` lors du push, et
réinjectées lors du deploy. Ce fichier est gitignored — ne le committe jamais.

## Dépendances

- `jq` : `brew install jq`
- `rsync` : inclus sur macOS
