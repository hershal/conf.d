#;;; -*- mode: shell-script; -*-

# xterm settings
export TERM="xterm-256color"

lock_system() {
    xlock& xset dpms force off;
}

# general command setup
alias s='screen'
alias ls='ls --color=auto'
alias ll='ls -lsha'
alias l='ll'
alias g='grep'
alias gv='grep -v'
alias y='yaourt'
alias ys='yaourt -S'
alias ysu='yaourt -Syu'
alias ysua='yaourt -Syua'
alias yss='yaourt -Ss'

# computational engine setup
alias mathematica='/usr/local/Wolfram/Mathematica/8.0/Executables/mathematica'
alias matab='/usr/local/MathWorks/Matlab/bin/matlab &'

# emacs stuff
export EDITOR='emacsclient -a ""'
alias emk='emacsclient -e "(kill-emacs)"'
alias emc='emacsclient -nc -a ""'
alias emn='emacsclient -n -a ""'
alias em='emacsclient -a ""'
alias emr='emacsclient -e "(remember-other-frame)"'

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
alias ka='git add'
alias kl='git log'
alias kd='git diff --minimal -b'
alias klg='git log --graph'
alias ga='git add'
alias gu='git pull'
alias gp='git push'
alias gpom='git push origin master'
alias gf='git fetch'
alias gca='git commit -a'
alias gcam='git commit -am'

