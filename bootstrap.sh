#!/usr/bin/env bash
# Full bootstrap for a fresh Ubuntu (server) machine.
#
# Idempotent: safe to re-run. Installs everything this dotfiles repo needs
# (per README.md), plus build tooling required by Neovim/Mason (this is what
# fixes the "python3 failed" error when Mason tries to install `black`),
# the Tmux Plugin Manager, and a recent Neovim build.
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

# build-essential + python3-venv/pip are what Mason needs to build/install
# LSPs and formatters (e.g. the "black" install failure: python3 -m venv
# fails without python3-venv on Debian/Ubuntu). nodejs/npm cover the JS/TS
# based tools Mason also installs.
$SUDO apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    unzip \
    tar \
    gzip \
    xz-utils \
    stow \
    zsh \
    tmux \
    python3 \
    python3-venv \
    python3-pip \
    pipx \
    nodejs \
    npm \
    eza \
    bat \
    fd-find \
    fzf \
    ripgrep \
    xclip

# zoxide is packaged in Ubuntu 22.04+ (universe); prefer it over the upstream
# install script, which has a history of misdetecting libc inside containers.
$SUDO apt-get install -y zoxide || true

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
# 3. zoxide (apt fallback for older Ubuntu without the package) + starship
# ---------------------------------------------------------------------------
if ! command -v zoxide >/dev/null 2>&1; then
    log "apt didn't provide zoxide (older Ubuntu?), installing from upstream script"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

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
#    (treesitter/lazy.nvim expect a recent release), so grab the latest
#    stable prebuilt binary from GitHub instead.
# ---------------------------------------------------------------------------
install_neovim() {
    if command -v nvim >/dev/null 2>&1; then
        log "Neovim already installed ($(nvim --version | head -1)), skipping"
        return
    fi
    log "Installing latest stable Neovim"
    local arch asset tmpdir
    arch="$(uname -m)"
    case "$arch" in
        x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
        *) warn "Unsupported arch '$arch' for prebuilt Neovim, falling back to apt"; $SUDO apt-get install -y neovim; return ;;
    esac
    tmpdir="$(mktemp -d)"
    # Newer Neovim releases use nvim-linux-<arch>.tar.gz; older ones used
    # nvim-linux64.tar.gz. Try current naming first, fall back if missing.
    if ! curl -sSfL -o "$tmpdir/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/${asset}"; then
        curl -sSfL -o "$tmpdir/nvim.tar.gz" \
            "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    fi
    $SUDO rm -rf /opt/nvim
    $SUDO mkdir -p /opt/nvim
    $SUDO tar -C /opt/nvim --strip-components=1 -xzf "$tmpdir/nvim.tar.gz"
    $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "$tmpdir"
}
install_neovim

# ---------------------------------------------------------------------------
# 5. Node via nvm (.config/zsh/.zshrc expects $HOME/.nvm) — gives Mason a
#    working npm for JS/TS-based servers alongside the apt nodejs above.
# ---------------------------------------------------------------------------
# Best-effort: the apt `nodejs`/`npm` installed above already cover Mason's
# JS/TS-based servers, so a hiccup here (registry unreachable, etc.) shouldn't
# take down the rest of the bootstrap.
if [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm + Node LTS"
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm install --lts || warn "nvm couldn't install a Node LTS build (network?); the apt nodejs/npm from step 1 still work"
    else
        warn "nvm install script failed; the apt nodejs/npm from step 1 still work"
    fi
fi

# ---------------------------------------------------------------------------
# 6. Stow the dotfiles themselves
# ---------------------------------------------------------------------------
log "Stowing dotfiles (--no-folding)"
./create-stow

# ---------------------------------------------------------------------------
# 7. Point zsh at $XDG_CONFIG_HOME/zsh
# ---------------------------------------------------------------------------
log "Configuring /etc/zsh/zshenv"
./setup-zshenv

# ---------------------------------------------------------------------------
# 8. Tmux Plugin Manager + plugins (tmux.conf expects it at the TPM default
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
# 9. Optional: make zsh the login shell
# ---------------------------------------------------------------------------
if [ "${CHANGE_SHELL:-0}" = "1" ]; then
    log "Changing login shell to zsh"
    $SUDO chsh -s "$(command -v zsh)" "$(whoami)"
fi

log "Bootstrap complete. Start a new zsh session (or 'exec zsh -l') to load everything."
