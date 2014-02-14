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
alias please='sudo !!'

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

update-links() {

    prefixstr=.
    TEMP=`getopt --options tp: --longoptions prefix:,test -- "$@"`
    if [ $? != 0 ]; then echo "wrong operands" >&2; return 1; fi
    eval set -- "$TEMP"

    while true; do
	case "$1" in
	    --prefix) prefixstr=$2; shift 2 ;;
	    --help|-h) echo "usage not implemented"; shift ;;
	    --) shift; break ;;
	    *) echo "INTERNAL ERROR!"; break ;;
	esac
    done

    for config in $@; do 
	ln -s -F $config $prefixstr`basename $config`;
    done;
}

cdl() {
    cd $@; l;
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

# map and rota taken from
# http://onthebalcony.wordpress.com/2008/03/08/just-for-fun-map-as-higher-order-function-in-bash/
map () { 
  if [ $# -le 1 ]; then 
    return 
  else 
    local f=$1 
    local x=$2 
    shift 2 
    local xs=$@ 

    $f $x 

    map "$f" $xs 
  fi 
}
rota () { 
  local f=$1 
  shift 
  local args=($@) 
  local idx=$(($#-1)) 
  local last=${args[$idx]} 
  args[$idx]= 

  $f $last ${args[@]} 
}

# *** Start configs stolen from @ericcrosson:
# This is some awesome shit, it auto-expands any "!" with a space
bind Space:magic-space

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
    *ARCH* )
	source ${configs}/bashrc.linux
	source ${configs}/bashrc.arch ;;
    *Linux* )
	source ${configs}/bashrc.linux ;;
    *Darwin* )
	source ${configs}/bashrc.osx ;;
    *Cygwin* )
	source ${configs}/bashrc.cygwin ;;
esac

