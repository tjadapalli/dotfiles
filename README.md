# dotfiles

Config for zsh, tmux, and Neovim, managed with [GNU Stow](https://www.gnu.org/software/stow/) and kept in sync across Linux machines.

## Quick start (fresh Ubuntu server)

```
git clone git@github.com:tjadapalli/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs all dependencies, symlinks the configs via stow,
points zsh at `$XDG_CONFIG_HOME/zsh`, installs the pinned Neovim build (see
below), and sets up the Tmux Plugin Manager plus its plugins. It's
idempotent — safe to re-run any time, e.g. after pulling updates.

Set `CHANGE_SHELL=1` to also make zsh your login shell:

```
CHANGE_SHELL=1 ./bootstrap.sh
```

## Try it in a throwaway container

```
./docker-test.sh          # ubuntu:24.04
./docker-test.sh 22.04    # or another Ubuntu release
```

Builds a disposable image, runs `bootstrap.sh` inside it, and drops you into
an interactive zsh shell with everything configured. Exit and the container
(`--rm`) is gone — nothing persists between runs.

## Manual install

```
./create-stow
```

Symlinks everything under `.config/` into `~/.config/`. Run `./remove-stow` to undo.

## zsh

zsh needs to know to look in `$XDG_CONFIG_HOME/zsh` instead of `$HOME` for
its dotfiles. This requires a one-time edit to `/etc/zsh/zshenv` (needs sudo):

```
./setup-zshenv
```

Dependencies:

```
sudo apt install eza bat fd-find fzf ripgrep universal-ctags zoxide build-essential python3-venv python3-pip nodejs npm
# starship isn't packaged for Ubuntu — grab the release binary directly
curl -sSfL -o /tmp/starship.tar.gz https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar -C /tmp -xzf /tmp/starship.tar.gz && install -m755 /tmp/starship ~/.local/bin/starship
# Ubuntu installs bat and fd under different names — symlink them so everything works
ln -s $(which batcat) ~/.local/bin/bat
ln -s $(which fdfind) ~/.local/bin/fd
```

## Neovim

This config targets a specific Neovim release, pinned in
[`.nvim-version`](./.nvim-version) (currently **0.12.4**) — the single
source of truth `bootstrap.sh` reads from. To upgrade, bump that file and
re-run `bootstrap.sh`.

`bootstrap.sh` downloads that exact version's tarball from GitHub releases
and installs it under `~/.local/nvim`, symlinked to `~/.local/bin/nvim`. To
do it by hand:

```
NVIM_VERSION=$(cat .nvim-version)
curl -sSfL -o /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
mkdir -p ~/.local/nvim && tar -C ~/.local/nvim --strip-components=1 -xzf /tmp/nvim.tar.gz
ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim
```

## Tmux Plugin Manager

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then either open tmux and press `prefix + I` to install the plugins listed
in `tmux.conf`, or run it headless the way `bootstrap.sh` does: start a
detached tmux session (so `tmux.conf`'s `run '~/.tmux/plugins/tpm/tpm'` line
actually gets sourced and sets up `TMUX_PLUGIN_MANAGER_PATH`), then run
`~/.tmux/plugins/tpm/bin/install_plugins` inside it.
