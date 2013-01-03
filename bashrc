#;;; -*- mode: shell-script; -*-

# xterm settings
export TERM="xterm-256color"

lock_system() {
    xlock& xset dpms force off;
}

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
export EDITOR='emacsclient -a ""'
alias emk='emacsclient -e "(kill-emacs)"'
alias emc='emacsclient -nc -a ""'
alias emn='emacsclient -n -a ""'
alias em='emacsclient -a ""'

emns() {
    emacsclient -na "" "/sudo::$*"
}
ems() {
    emacsclient -a "" "/sudo::$*"
}
emcs() {
    emacsclient -nc -a "" "/sudo::$*"
}

editor() {
    emacsclient -a "" -c "$@"
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

