#;;; -*- mode: shell-script; -*-

# bash-specific configuration
if [[ -n ${BASH} ]]; then

    # General Shell Settings
    export PS1="[\u@\h \W]\$ "
    export PS2=">"

    # Enables tab-completion while sudo-ing
    complete -cf sudo

    # Enable some shell extensions
    shopt -s extglob
    shopt -s dotglob
    shopt -s checkwinsize
    shopt -s histappend
    shopt -s cdspell

    # This auto-expands any "!" with a space
    bind Space:magic-space
fi

# xterm settings
export TERM="xterm-256color"

export email='hershal.bhave@gmail.com'

# Append
export PATH=$PATH:~/conf.d/bin

# Load OS-specific configs
export configs=~/conf.d
source ${configs}/bashrc.aliases
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

ev() {
    evince $@ > /dev/null 2>&1 &
}

editor() {
    emacsclient -a "" -c "$@"
}

update_links() {
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

# don't ask
modpath () {
    modpathargs=${@+"$@"};
    . ${configs}/modpath.sh;
    unset modpathargs
}

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
export HISTIGNORE=' *'

# Ignore duplicates in history
export HISTCONTROL=ignoredups

# Find a file with pattern $1 in name and execute $2 on it:
ffand() { find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \; ; }

# Find files matching a given pattern
ff() { find . -type f -iname '*'$*'*' -ls ; }

# *** End configs stolen from @ericcrosson:

# Miscellaneous platform-sensitive configs
unset -f which 2> /dev/null
if [[ -f ${_WHICH_BINARY} ]]; then
    which () {
        (alias; declare -f) | ${_WHICH_BINARY} \
            --tty-only \
            --read-alias \
            --read-functions \
            --show-tilde \
            --show-dot $@
    }
    export -f which > /dev/null
fi

# Taken from Petar Marinov
# http://geocities.com/h2428/petar/bash_acd.htm
if [[ -n ${BASH} ]]; then
    cd_func () {
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
fi

qr() { qrencode -t ansi256 -o - "$*"; }
cl() { cd $@ && l ; }
mkc() { mkdir -p $@ && cd $@ ; }
