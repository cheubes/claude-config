# claude-config

Personal Claude Code configuration, versioned and syncable.

## Structure

```
claude-config/
├── scripts/
│   ├── get.sh        # Sync ~/.claude → repo
│   └── deploy.sh     # Sync repo → ~/.claude
├── hooks/            # Claude Code hooks (PostToolUse, PreToolUse...)
├── commands/         # Custom slash commands
├── settings.json     # Config without secrets
├── settings.secrets.json  # Local secrets, gitignored
├── CLAUDE.md         # Global instructions
├── LICENSE           # CC0 1.0 Universal
└── .gitignore
```

## Initial setup

```bash
# 1. Make scripts executable
chmod +x scripts/get.sh scripts/deploy.sh

# 2. Connect to GitHub remote
git remote add origin git@github.com:YOUR_USER/claude-config.git

# 3. First sync
./scripts/get.sh
```

## Daily usage

```bash
# Save current config
./scripts/get.sh

# Deploy on a new machine
./scripts/deploy.sh

# Test without modifying files
./scripts/get.sh --dry-run
./scripts/deploy.sh --dry-run
```

## Secrets

Environment variables (API keys, tokens) in `settings.json` are automatically
extracted into `settings.secrets.json` on get, and re-injected on deploy.
This file is gitignored: never commit it.

## Dependencies

- `jq`: `brew install jq`
- `rsync`: included on macOS

## License

Code and content are dedicated to the public domain under
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).
See [LICENSE](LICENSE).
