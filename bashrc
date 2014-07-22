
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
alias gv='grep -v'
alias chmox='chmod +x'
alias please='sudo $(history -p !!)'

# emacs stuff
export EDITOR='emacsclient -a "" '
alias emc='$EDITOR  -nc  '
alias emn='$EDITOR -n '
alias em='$EDITOR  -nw'
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

# git stuff
git_diff_useful() { git diff --minimal -b --color=always $@ | less -R; }
alias k='git status'
alias kc='git commit'
alias kb='git branch'
alias kh='git checkout'
alias ka='git add'
alias kl='git log --pretty="%C(blue)[%ci]%Creset %Cgreen[%cn]%Creset %C(auto)%h%Creset %s%C(auto)%d%Creset" --graph'
alias kll='git log --stat --graph --summary'
alias kd='git_diff_useful'
alias klg='git log --graph'
alias kf='git fetch'
alias kca='git commit -a'
alias kcam='git commit -am'
alias ksd='git svn dcommit'
alias g='git'
alias gu='git pull'
alias gp='git push'
alias gpom='git push origin master'

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

cdl() {
    cd $@ && l
}

if [[ -f ${EXPANDED_WHICH_BINARY} ]]; then
    which () {
        (alias; declare -f) | ${EXPANDED_WHICH_BINARY} \
            --tty-only \
            --read-alias \
            --read-functions \
            --show-tilde \
            --show-dot $@
    }
    export -f which
fi

# Taken from Petar Marinov
# http://geocities.com/h2428/petar/bash_acd.htm
cd_func ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    #
    # Extract dir N from dirs
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=$adir
  fi

  # '~' has to be substituted by ${HOME}
  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  # Now change to the new dir and add to the top of the stack
  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

  # Trim down everything beyond 11th entry
  popd -n +11 2>/dev/null 1>/dev/null

  # Remove any other occurence of this dir, skipping the top of the stack
  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0
    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == "${the_new_dir}" ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=cnt-1
    fi
  done

  return 0
}

alias cd='cd_func '
alias sd='cd -- '
