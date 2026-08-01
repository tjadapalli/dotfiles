# Better ls (icons toggle: `disable-icons` / `enable-icons`, default enabled)
typeset -g EZA_ICONS_ENABLED=1

_eza_icon_flag() {
    (( EZA_ICONS_ENABLED )) && print -- --icons
}

disable-icons() {
    EZA_ICONS_ENABLED=0
    echo "eza icons disabled"
}

enable-icons() {
    EZA_ICONS_ENABLED=1
    echo "eza icons enabled"
}

ls() { eza $(_eza_icon_flag) "$@" }
ll() { eza -lh $(_eza_icon_flag) --git "$@" }
la() { eza -lah $(_eza_icon_flag) --git "$@" }
tree() { eza --tree $(_eza_icon_flag) "$@" }

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
# alias cat='bat'

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# =========================================================
# Editor
# =========================================================

# alias vim='nvim'

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# =========================================================
# Video
# =========================================================

alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
