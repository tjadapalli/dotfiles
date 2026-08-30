# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start (fresh Ubuntu server)

```
git clone git@github.com:tjadapalli/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` does everything below in one shot: installs all dependencies
(including `build-essential`, `python3-venv`/`python3-pip`, and Node — the
packages Neovim's Mason needs to build/install LSPs and formatters, e.g. the
`black` "python3 failed with exit code 1" error is caused by a missing
`python3-venv`), symlinks the configs via stow, points zsh at
`$XDG_CONFIG_HOME/zsh`, and installs the Tmux Plugin Manager plus its
plugins. It's idempotent — safe to re-run any time (after pulling updates,
for example).

Set `CHANGE_SHELL=1` to also make zsh your login shell:

```
CHANGE_SHELL=1 ./bootstrap.sh
```

## Try it in a throwaway container

To test the whole setup without touching your actual machine:

```
./docker-test.sh          # ubuntu:24.04
./docker-test.sh 22.04    # or another Ubuntu release
```

This builds a disposable image, runs `bootstrap.sh` inside it during the
build, and drops you straight into an interactive zsh shell with everything
already configured. Exit the shell and the container (`--rm`) is gone —
nothing persists between runs.

## Manual install

If you'd rather do it by hand instead of running `bootstrap.sh`:

```
./create-stow
```

Symlinks everything under `.config/` into `~/.config/`. Run `./remove-stow` to undo.

## zsh

### Point zsh at the config directory

zsh needs to know to look in `$XDG_CONFIG_HOME/zsh` instead of `$HOME` for its dotfiles. This requires a one-time edit to `/etc/zsh/zshenv` (needs sudo):

```
./setup-zshenv
```

### Dependencies

```
sudo apt install eza bat fd-find fzf ripgrep zoxide build-essential python3-venv python3-pip nodejs npm
# starship isn't packaged for Ubuntu — grab the release binary directly
curl -sSfL -o /tmp/starship.tar.gz https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar -C /tmp -xzf /tmp/starship.tar.gz && install -m755 /tmp/starship ~/.local/bin/starship
# Ubuntu installs bat and fd under different names — symlink them so everything works
ln -s $(which batcat) ~/.local/bin/bat
ln -s $(which fdfind) ~/.local/bin/fd
```

## Neovim

Ubuntu's packaged Neovim is often too old for modern plugins (treesitter,
lazy.nvim expect a recent release). `bootstrap.sh` installs the latest
stable build straight from GitHub releases; do it by hand with:

```
curl -sSfL -o /tmp/nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo mkdir -p /opt/nvim && sudo tar -C /opt/nvim --strip-components=1 -xzf /tmp/nvim.tar.gz
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
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
