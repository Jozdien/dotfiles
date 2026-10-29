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

    # -n: replace an existing symlink to a directory instead of linking inside it
    if [ -L "$dst" ]; then
        # Already a symlink — update it silently
        ln -sfn "$src" "$dst"
    elif [ -e "$dst" ]; then
        # Real file exists — back it up first
        echo "  ⚠ Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
        ln -sfn "$src" "$dst"
    else
        ln -sfn "$src" "$dst"
    fi
    echo "  ✓ $dst → $src"
}

# --- tmux --------------------------------------------------------------------
link_file "$CONFIGS/.tmux.conf" "$HOME/.tmux.conf"

# --- Shell helpers (tp: per-project tmux sessions) ---------------------------
link_file "$CONFIGS/tp.sh" "$HOME/.tp.sh"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q '\.tp\.sh' "$rc"; then
        printf '\n[ -f ~/.tp.sh ] && . ~/.tp.sh  # dotfiles: tp tmux helper\n' >> "$rc"
        echo "  ✓ $rc sources ~/.tp.sh"
    fi
done

# --- Claude CLI config -------------------------------------------------------
# We symlink individual files/dirs inside ~/.claude, NOT the whole directory,
# because ~/.claude has runtime state we don't want to clobber or track.
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SRC="$SCRIPT_DIR/.claude"
mkdir -p "$CLAUDE_DIR"

# CLAUDE.md — your global instructions. A real file that already imports this
# one (e.g. a wrapper adding org instructions like Redwood's) is left alone.
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ] \
    && grep -q '@~/dotfiles/.claude/CLAUDE.md' "$CLAUDE_DIR/CLAUDE.md"; then
    echo "  ✓ $CLAUDE_DIR/CLAUDE.md imports dotfiles CLAUDE.md; leaving it"
else
    link_file "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# Skills — link each one individually so skills installed from elsewhere
# (e.g. Redwood's) can live alongside them in ~/.claude/skills
if [ -d "$CLAUDE_SRC/skills" ]; then
    # Migrate from the old layout, where the whole dir was one symlink
    [ -L "$CLAUDE_DIR/skills" ] && rm "$CLAUDE_DIR/skills"
    mkdir -p "$CLAUDE_DIR/skills"
    for skill in "$CLAUDE_SRC/skills"/*/; do
        link_file "${skill%/}" "$CLAUDE_DIR/skills/$(basename "$skill")"
    done
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