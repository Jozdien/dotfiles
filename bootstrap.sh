#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# bootstrap.sh — Run once on a fresh machine. Safe to re-run (idempotent).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap.sh | bash
#   (or just ./bootstrap.sh if you've already cloned)
# =============================================================================

DOTFILES_REPO="https://github.com/Jozdien/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# --- Detect environment ------------------------------------------------------
detect_env() {
    if [ -d "/workspace" ] && [ -f "/etc/runpod.conf" ] 2>/dev/null || [ -n "${RUNPOD_POD_ID:-}" ]; then
        echo "runpod"
    elif curl -sf -m 1 "http://metadata.google.internal/computeMetadata/v1/" -H "Metadata-Flavor: Google" &>/dev/null; then
        echo "gcloud"
    else
        echo "generic"
    fi
}

ENV=$(detect_env)
echo "==> Detected environment: $ENV"

# On RunPod, prefer /workspace since the root filesystem is ephemeral
if [ "$ENV" = "runpod" ]; then
    DOTFILES_DIR="/workspace/dotfiles"
fi

# --- Helper: install if missing ----------------------------------------------
ensure_installed() {
    local cmd="$1"
    shift
    if command -v "$cmd" &>/dev/null; then
        echo "  ✓ $cmd already installed"
        return 0
    fi
    echo "  → Installing $cmd..."
    "$@"
}

# --- Core tool installs ------------------------------------------------------
echo "==> Installing tools..."

# apt-based installs (batch them)
APT_PACKAGES=()
command -v tmux  &>/dev/null || APT_PACKAGES+=(tmux)
command -v curl  &>/dev/null || APT_PACKAGES+=(curl)
command -v git   &>/dev/null || APT_PACKAGES+=(git)

if [ ${#APT_PACKAGES[@]} -gt 0 ]; then
    echo "  → apt-get install: ${APT_PACKAGES[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${APT_PACKAGES[@]}"
fi

# uv (Python package manager)
ensure_installed uv bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
# Make sure uv is on PATH for the rest of this script
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# gh (GitHub CLI) — for git auth
ensure_installed gh bash -c '
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y))
    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp)
    wget -qO "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg < "$out" >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq
    sudo apt install gh -y -qq
'

# --- Git config --------------------------------------------------------------
echo "==> Configuring git..."

GIT_NAME="${GIT_NAME:-Jozdien}"
GIT_EMAIL="${GIT_EMAIL:-jozdien@gmail.com}"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Check git auth, prompt if needed
if ! gh auth status &>/dev/null; then
    echo ""
    echo "  ⚠ GitHub not authenticated. Running 'gh auth login'..."
    echo "  (If non-interactive, set GITHUB_TOKEN env var instead)"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo "$GITHUB_TOKEN" | gh auth login --with-token
    else
        gh auth login
    fi
fi

# --- Clone dotfiles if not already present -----------------------------------
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "==> Cloning dotfiles repo..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "==> Dotfiles already cloned at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only || true
fi

# --- Hand off to sync --------------------------------------------------------
echo "==> Running sync..."
bash "$DOTFILES_DIR/sync.sh"

echo ""
echo "==> Bootstrap complete! Environment: $ENV"
echo "    Dotfiles at: $DOTFILES_DIR"
echo "    Run 'cd $DOTFILES_DIR && ./sync.sh' anytime to re-sync configs."