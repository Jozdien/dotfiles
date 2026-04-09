#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sync.sh — Symlink configs from this repo into the right places.
#            Safe to run repeatedly. Run after git pull to pick up changes.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$SCRIPT_DIR/configs"

echo "==> Syncing configs from $SCRIPT_DIR"

# --- Helper: create a symlink, backing up any existing real file -------------
link_file() {
    local src="$1"
    local dst="$2"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        # Already a symlink — update it silently
        ln -sf "$src" "$dst"
    elif [ -e "$dst" ]; then
        # Real file exists — back it up first
        echo "  ⚠ Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
        ln -sf "$src" "$dst"
    else
        ln -sf "$src" "$dst"
    fi
    echo "  ✓ $dst → $src"
}

# --- tmux --------------------------------------------------------------------
link_file "$CONFIGS/.tmux.conf" "$HOME/.tmux.conf"

# --- Claude CLI config -------------------------------------------------------
# We symlink individual files/dirs inside ~/.claude, NOT the whole directory,
# because ~/.claude has runtime state we don't want to clobber or track.
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SRC="$SCRIPT_DIR/.claude"
mkdir -p "$CLAUDE_DIR"

# CLAUDE.md — your global instructions
link_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Skills directory (whole dir is fine to symlink)
if [ -d "$CLAUDE_SRC/skills" ] && [ "$(ls -A "$CLAUDE_SRC/skills" 2>/dev/null)" ]; then
    link_file "$CLAUDE_SRC/skills" "$CLAUDE_DIR/skills"
fi

# settings.json — contains permissions config
# NOTE: Claude Code may overwrite this at runtime. If that's a problem,
# consider copying instead of symlinking. Uncomment the alternative below.
if [ -f "$CLAUDE_SRC/settings.json" ]; then
    link_file "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
    # Alternative: copy instead of symlink (Claude Code won't clobber repo copy)
    # cp "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
fi

# --- Any other dotfiles (add more as needed) ---------------------------------
# link_file "$CONFIGS/.bashrc_extras" "$HOME/.bashrc_extras"
# link_file "$CONFIGS/.vimrc" "$HOME/.vimrc"

echo ""
echo "==> Sync complete."