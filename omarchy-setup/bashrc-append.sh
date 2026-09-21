# Navigation (.. ... and cd already provided by Omarchy)
alias ....='cd ../../..'

# Listing
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Git (g/gcm/gcam/gcad already provided by Omarchy)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Quality of life
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.bashrc'

mkcd() { mkdir -p "$1" && cd "$1"; }

# Arch package management
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacq='pacman -Qi'
