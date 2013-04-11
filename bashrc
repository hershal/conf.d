#;;; -*- mode: shell-script; -*-

# General Shell Settings
export PS1="[\u@\h \W]\$ "
export PS2=">"

# xterm settings
export TERM="xterm-256color"

export email='hershal.bhave@gmail.com'

# Append 
export PATH=$PATH:~/conf.d/bin

# To enable tab-completion while sudo-ing
complete -cf sudo

# Enable some shell extensions
shopt -s extglob
shopt -s dotglob
shopt -s checkwinsize
shopt -s histappend
shopt -s cdspell

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
alias yua='yaourt -Sua'
alias ysua='yaourt -Syua'
alias yss='yaourt -Ss'

# Computational Engines setup
alias mathematica='/usr/local/Wolfram/Mathematica/8.0/Executables/mathematica'
alias matab='/usr/local/MathWorks/Matlab/bin/matlab &'
# Octave doesn't need anything special; it just works

# emacs stuff
export EDITOR='emacsclient -a ""'
alias emk='emacsclient -e "(kill-emacs)"'
alias emc='emacsclient -nc -a ""'
alias emn='emacsclient -n -a ""'
alias em='emacsclient -a ""'
alias emr='emacsclient -e "(remember-other-frame)"'

lock_system() {
    slock& xset dpms force off;
}
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

eve() {
    evince $@ > /dev/null 2>&1 & exit
}


# git stuff
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
alias gpbl='gp bravo master && gp light master'
alias gsd='git svn dcommit'
alias tagsgen='find . -regex ".*\.[cChH]\(pp\)?" -print | etags -'
alias ev='evince 2>/dev/null'
alias chmox='chmod +x'


# Until EOF are configs stolen from @ericcrosson:

export BROWSER='chromium &2>/dev/null'
export HISTIGNORE=' *'

# ignore duplicates in history
export HISTCONTROL=ignoredups 

# Find a file with pattern $1 in name and execute $2 on it:
function ffand() { find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \; ; }

# Find files matching a given pattern
function ff() { find . -type f -iname '*'$*'*' -ls ; }
