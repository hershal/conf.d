#;;; -*- mode: shell-script; -*-

# xterm settings
export TERM="xterm-256color"

# general command setup
alias ls='ls --color=auto'
alias ll='ls --color=auto -lsha'
alias yu='yaourt -Syu'
alias yua='yaourt -Syua'
alias ys='yaourt -Ss'

# computational engine setup
alias mathematica='/usr/local/Wolfram/Mathematica/8.0/Executables/mathematica'
alias matab='/usr/local/MathWorks/Matlab/bin/matlab &'

# emacs stuff
export EDITOR='emacsclient -c -a ""'
alias emc='emacsclient -nc -a ""'
alias emm='emacsclient -n -a ""'
alias em='emacsclient -a ""'
ecs() {
    emacsclient -a "emacs --daemon" "/sudo::$*"
}

# git stuff, one requires emacs stuff first
alias k='git status'
alias kl='git log'
alias kd='git diff --minimal -b'
alias klg='git log --graph'
alias gu='git pull'
alias gf='git fetch'
alias gca='git commit -a'
alias gcam='git commit -am'

