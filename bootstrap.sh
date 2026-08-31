#!/usr/bin/env bash
# Full bootstrap for a fresh Ubuntu (server) machine.
#
# Idempotent: safe to re-run. Installs everything this dotfiles repo needs
# (per README.md), plus build tooling required by Neovim/Mason, the Tmux
# Plugin Manager, and the pinned Neovim build (version in .nvim-version).
#
# Usage:
#   ./bootstrap.sh              # full install
#   CHANGE_SHELL=1 ./bootstrap.sh   # also chsh the current user to zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

log() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# sudo shim: work whether we're root (e.g. inside a container) or a normal user
# ---------------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required (and not installed) for a non-root user. Install it first." >&2
        exit 1
    fi
    SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
log "Updating apt and installing system packages"
$SUDO apt-get update -y

# python3-venv is needed for Mason's pip-based installs; unzip for its
# .zip-packaged ones (e.g. clangd); xclip backs tmux-yank.
# Keep this list in sync with README.md's "Dependencies" manual-install line.
$SUDO apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    stow \
    zsh \
    tmux \
    python3 \
    python3-venv \
    python3-pip \
    eza \
    bat \
    fd-find \
    fzf \
    ripgrep \
    universal-ctags \
    xclip \
    unzip \
    zoxide

# ---------------------------------------------------------------------------
# 2. Ubuntu names bat/fd differently — symlink so configs that call
#    `bat`/`fd` (see .config/zsh) work unmodified.
# ---------------------------------------------------------------------------
log "Linking batcat -> bat, fdfind -> fd"
mkdir -p "$HOME/.local/bin"
if command -v batcat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
if command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# 3. starship
# ---------------------------------------------------------------------------
# starship isn't packaged for Ubuntu; the upstream install script also does
# its own libc/arch detection which can misfire in some containers, so pull
# the prebuilt binary straight from the GitHub release instead.
if ! command -v starship >/dev/null 2>&1; then
    log "Installing starship"
    arch="$(uname -m)"
    case "$arch" in
        x86_64) starship_asset="starship-x86_64-unknown-linux-gnu.tar.gz" ;;
        aarch64|arm64) starship_asset="starship-aarch64-unknown-linux-gnu.tar.gz" ;;
        *) starship_asset="" ;;
    esac
    if [ -n "$starship_asset" ]; then
        tmpdir="$(mktemp -d)"
        curl -sSfL -o "$tmpdir/starship.tar.gz" \
            "https://github.com/starship/starship/releases/latest/download/${starship_asset}"
        tar -C "$tmpdir" -xzf "$tmpdir/starship.tar.gz"
        install -m755 "$tmpdir/starship" "$HOME/.local/bin/starship"
        rm -rf "$tmpdir"
    else
        warn "Unsupported arch '$arch' for starship, skipping"
    fi
fi
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# 4. Neovim — Ubuntu's apt package is often too old for modern plugins
#    (treesitter/lazy.nvim expect a recent release), so grab a pinned
#    stable prebuilt binary from GitHub instead. The version this config
#    targets lives in .nvim-version (single source of truth — bump that
#    file to upgrade).
# ---------------------------------------------------------------------------
NVIM_VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/.nvim-version")"

install_neovim() {
    if command -v nvim >/dev/null 2>&1 && nvim --version | head -1 | grep -qF "NVIM v${NVIM_VERSION}"; then
        log "Neovim v${NVIM_VERSION} already installed, skipping"
        return
    fi
    log "Installing Neovim v${NVIM_VERSION}"
    local arch asset tmpdir
    arch="$(uname -m)"
    case "$arch" in
        x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
        *) warn "Unsupported arch '$arch' for prebuilt Neovim, falling back to apt"; $SUDO apt-get install -y neovim; return ;;
    esac
    tmpdir="$(mktemp -d)"
    curl -sSfL -o "$tmpdir/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${asset}"
    rm -rf "$HOME/.local/nvim"
    mkdir -p "$HOME/.local/nvim"
    tar -C "$HOME/.local/nvim" --strip-components=1 -xzf "$tmpdir/nvim.tar.gz"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmpdir"
}
install_neovim

# ---------------------------------------------------------------------------
# 5. Stow the dotfiles themselves
# ---------------------------------------------------------------------------
log "Stowing dotfiles (--no-folding)"
# GNU Stow silently no-ops (exit 0, "skipping target which was current stow
# directory .") if this repo's parent directory is $HOME itself — i.e. if
# this checkout lives directly at ~/dotfiles rather than nested a level
# deeper (~/workspace/dotfiles, ~/git/dotfiles, etc). create-stow's
# `stow -d .. -t ~` needs that nesting, so fail loudly instead of silently
# doing nothing.
if [ "$(cd .. && pwd)" = "$HOME" ]; then
    echo "error: this checkout is directly under \$HOME ($SCRIPT_DIR)." >&2
    echo "       'stow -d .. -t ~' requires the repo to be nested one level" >&2
    echo "       deeper than \$HOME (e.g. ~/workspace/dotfiles), otherwise Stow" >&2
    echo "       treats the stow dir and the target as the same path and" >&2
    echo "       silently symlinks nothing. Move the clone and re-run." >&2
    exit 1
fi
./create-stow
if [ ! -e "$HOME/.config/nvim/init.lua" ] && [ -e "$SCRIPT_DIR/.config/nvim/init.lua" ]; then
    echo "error: stow reported success but ~/.config/nvim/init.lua wasn't linked." >&2
    echo "       Run './create-stow' manually and check its output for warnings." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 6. Point zsh at $XDG_CONFIG_HOME/zsh
# ---------------------------------------------------------------------------
log "Configuring /etc/zsh/zshenv"
./setup-zshenv

# ---------------------------------------------------------------------------
# 7. Tmux Plugin Manager + plugins (tmux.conf expects it at the TPM default
#    path, ~/.tmux/plugins/tpm)
# ---------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    log "Installing Tmux Plugin Manager"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
log "Installing tmux plugins via tpm"
# install_plugins needs TMUX_PLUGIN_MANAGER_PATH, which is only set once
# tmux.conf's `run '~/.tmux/plugins/tpm/tpm'` line has actually been sourced
# inside a live tmux server — calling the script directly, outside tmux,
# fails with "Tmux Plugin Manager not configured". So spin up a throwaway
# detached session (which sources tmux.conf via the default XDG lookup),
# run the installer inside it, then tear the session down.
tmux kill-server 2>/dev/null || true
if tmux new-session -d -s __bootstrap_tpm 2>/tmp/tpm_session.err; then
    tmux send-keys -t __bootstrap_tpm \
        "$TPM_DIR/bin/install_plugins; tmux kill-session -t __bootstrap_tpm" Enter
    for _ in $(seq 1 60); do
        tmux has-session -t __bootstrap_tpm 2>/dev/null || break
        sleep 1
    done
    tmux kill-server 2>/dev/null || true
else
    warn "couldn't start a tmux session to install plugins ($(cat /tmp/tpm_session.err 2>/dev/null)); run 'prefix + I' inside tmux manually"
fi

# ---------------------------------------------------------------------------
# 8. Optional: make zsh the login shell
# ---------------------------------------------------------------------------
if [ "${CHANGE_SHELL:-0}" = "1" ]; then
    log "Changing login shell to zsh"
    $SUDO chsh -s "$(command -v zsh)" "$(whoami)"
fi

log "Bootstrap complete. Start a new zsh session (or 'exec zsh -l') to load everything."
