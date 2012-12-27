#;;; -*- mode: shell-script; -*-

# xterm settings
export TERM="xterm-256color"

# general command setup
alias ls='ls --color=auto'
alias ll='ls --color=auto -lsha'
alias yu='yaourt -Syua'
alias ys='yaourt -Ss'

# computational engine setup
alias mathematica='/usr/local/Wolfram/Mathematica/8.0/Executables/mathematica'
alias matab='/usr/local/MathWorks/Matlab/bin/matlab &'

# git stuff
alias k='git status'
alias gu='git pull'
alias gf='git fetch'
alias gca='git commit -am'

# emacs stuff
export EDITOR="emacsclient -nc -a vim"
alias ec='emacsclient -nc -a vim'
alias et='emacsclient -a vim'
ecs() { emacsclient -c -n -a emacs "/sudo::$*" }
ets() { emacsclient -t -a emacs "/sudo::$*" }
