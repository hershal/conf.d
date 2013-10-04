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

# General command setup
alias s='screen'
alias ls='ls --color=auto'
alias l='ls -lsha'
alias less='less -R -i'
alias g='grep'
alias gv='grep -v'
alias chmox='chmod +x'

# emacs stuff
export EDITOR='emacsclient -a "" '
alias emc='$EDITOR  -nc  '
alias emn='$EDITOR -n '
alias em='$EDITOR  '
alias emr='emacsclient -e "(remember-other-frame)"'
alias emk='emacsclient -e "(kill-emacs)"'

editor() {
    emacsclient -a "" -c "$@"
}

# git stuff
alias k='git status'
alias kc='git commit'
alias kb='git branch'
alias ka='git add'
alias kl='git log'
alias kll='git log --stat --graph'
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

# If the GPG agent is running and its PID file is created then source it
if [ -f "${HOME}/.gpg-agent-info" ]; then
  . "${HOME}/.gpg-agent-info"
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK
fi

# *** Start configs stolen from @ericcrosson:

export HISTIGNORE=' *'

# ignore duplicates in history
export HISTCONTROL=ignoredups 

# Find a file with pattern $1 in name and execute $2 on it:
function ffand() { find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \; ; }

# Find files matching a given pattern
function ff() { find . -type f -iname '*'$*'*' -ls ; }

# *** End configs stolen from @ericcrosson:

# Load OS-specific configs
export configs=~/conf.d
case `uname -a` in
    *Linux* )
	source ${configs}/bashrc.linux ;;
    *ARCH* )
	source ${configs}/bashrc.linux
	source ${configs}/bashrc.arch ;;
    *Darwin* )
	source ${configs}/bashrc.osx ;;
    *Cygwin* )
	source ${configs}/bashrc.cygwin ;;
esac

