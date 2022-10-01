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

    # Only do this in interactive shells
    if [ -z "$PS1" ]; then
        # This auto-expands any "!" with a space
        bind Space:magic-space
    fi
fi

# xterm settings
export TERM="xterm-256color"

export email='hershal.bhave@gmail.com'
export EDITOR='emacsclient -a "vi"'

# Load OS-specific configs
export configs=${HOME}/conf.d
source ${configs}/bashrc.aliases

hasbin() {
    command -v $@ > /dev/null
    return $?
}

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

update_links() {
    prefixstr=.

    for config in $@; do
        mv -f ${prefixstr}$(basename ${config}) ${prefixstr}$(basename ${config}).bak
        ln -s -F ${config} ${prefixstr}$(basename ${config})
    done;
}

# don't ask
modpath () {
    modpathargs=${@+"$@"};
    . ${configs}/modpath.sh;
    unset modpathargs
}

# new generation of modpath
modpath-ng() {
    outfile=/tmp/modpath-ng.$$;
    ${configs}/modpath-ng $@ -o ${outfile}
    source ${outfile}
    rm -f ${outfile}
}

modpath -q ~/conf.d/bin
modpath -q ~/bashrc.d/bin
modpath -q ~/bin

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
if [[ -n ${BASH} ]]; then
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

if [[ -d ${HOME}/bashrc.d/ ]]; then
    for conf in ${HOME}/bashrc.d/*; do
        if [ -f ${conf} ]; then
            source ${conf}
        fi
    done
fi

# load nvm
export NVM_DIR="$(readlink -e $HOME/.nvm)"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
modpath -q "$HOME/.rvm/bin"


nguard() {
    while test $(eval $@ > /dev/null 2>&1; echo $?) = 0; do sleep 1; done;
}

guard() {
    while test $(eval $@ > /dev/null 2>&1; echo $?) != 0; do sleep 1; done;
}

cl() {
    cd $@ && l
}

# Enable bm bookmark manager https://www.npmjs.com/package/bookmark
alias bm="source bm"

# Enable extensions in the 'pass' command
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
