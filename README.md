# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Install

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
sudo apt install eza bat fd-find fzf ripgrep
# install zoxide and starship separately
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh
# Ubuntu installs bat and fd under different names — symlink them so everything works
ln -s $(which batcat) ~/.local/bin/bat
ln -s $(which fdfind) ~/.local/bin/fd
```
