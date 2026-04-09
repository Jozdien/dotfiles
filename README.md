# dotfiles

Personal machine setup for ephemeral GPU/VM environments.

## Fresh machine (bootstrap)

```bash
# Option A: if you can clone first (git auth already works)
git clone https://github.com/Jozdien/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh

# Option B: curl one-liner (bootstrap clones itself)
curl -fsSL https://raw.githubusercontent.com/Jozdien/dotfiles/main/bootstrap.sh | bash
```

## Update configs on an existing machine

```bash
cd ~/dotfiles   # or /workspace/dotfiles on RunPod
git pull
# That's it — symlinks mean configs are already updated.
# If you added NEW files that need new symlinks:
./sync.sh
```

## What goes where

```
dotfiles/
├── bootstrap.sh              # one-time: install tools, set up git, clone repo, call sync
├── sync.sh                   # repeatable: create/update symlinks
├── .claude/
│   ├── CLAUDE.md             # → ~/.claude/CLAUDE.md
│   ├── settings.json         # → ~/.claude/settings.json
│   └── skills/               # → ~/.claude/skills/
├── configs/
│   └── .tmux.conf            # → ~/.tmux.conf
└── README.md
```

## Adding a new config file

1. Put the file in `configs/`
2. Add a `link_file` call in `sync.sh`
3. Commit, push, `git pull` on other machines

## Design choices

- **Symlinks, not copies**: `git pull` = instant config update, no extra sync step.
- **Individual Claude files, not whole dir**: `~/.claude` has runtime state we don't track.
- **Idempotent everything**: safe to run bootstrap/sync multiple times.
- **Environment detection**: auto-detects RunPod vs GCloud vs generic Linux.