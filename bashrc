#;;; -*- mode: shell-script; -*-

# bash-specific configuration
if [[ -n ${BASH} ]]; then

    # Source global definitions (bash-completion et al. for non-login shells)
    [ -f /etc/bashrc ] && . /etc/bashrc

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

    # Free C-q / C-s (XON/XOFF flow control) so they're usable as keys (tmux 2nd prefix)
    [[ $- == *i* ]] && stty -ixon 2>/dev/null

    # Only do this in interactive shells
    if [ -z "$PS1" ]; then
        # This auto-expands any "!" with a space
        bind Space:magic-space
    fi
fi

# xterm settings
export TERM="xterm-256color"

export EDITOR='emacsclient -a "vi"'

# Load OS-specific configs
export configs=${HOME}/conf.d
source ${configs}/bashrc.aliases

hasbin() {
    command -v $@ > /dev/null
    return $?
}

case `uname -a` in
    *Linux* )
        source ${configs}/bashrc.linux ;;
    *Darwin* )
        source ${configs}/bashrc.macos ;;
esac

ev() {
    evince $@ > /dev/null 2>&1 &
}

update_links() {
    # Symlink ~/.<name> -> <conf.d path>, replacing any existing symlink.
    # No .bak (the old version backed up the *symlink* and churned junk). A real,
    # non-symlink file in the way is left alone with a warning — pass -f to force
    # over it anyway.   Usage: update_links [-f] <path> [<path> ...]
    local force=
    [[ $1 == -f ]] && { force=1; shift; }
    for config in "$@"; do
        local link=".$(basename "$config")"
        if [[ -z $force && -e $link && ! -L $link ]]; then
            echo "update_links: ~/$link exists and is not a symlink — skipping (use -f to force)" >&2
            continue
        fi
        ln -sfn "$config" "$link"
    done
}

# don't ask
modpath () {
    modpathargs=${@+"$@"};
    . ${configs}/modpath.sh;
    unset modpathargs
}

# new generation of modpath
#modpath-ng() {
#    outfile=/tmp/modpath-ng.$$;
#    ${configs}/modpath-ng $@ -o ${outfile}
#    source ${outfile}
#    rm -f ${outfile}
#}

# (personal bin dirs are prepended to PATH at the very end of this file)

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
# if [[ -n ${BASH} ]]; then
#     unset -f which 2> /dev/null
#     if [[ -f ${_WHICH_BINARY} ]]; then
#         which () {
#             (alias; declare -f) | ${_WHICH_BINARY} \
#                                       --tty-only \
#                                       --read-alias \
#                                       --read-functions \
#                                       --show-tilde \
#                                       --show-dot $@
#         }
#         export -f which > /dev/null
#     fi
# fi

# Taken from Petar Marinov
# http://geocities.com/h2428/petar/bash_acd.htm
if [[ -n ${BASH} ]]; then
    cd_func () {
        local x2 the_new_dir adir index
        local -i cnt

        # `cd -` lists the numbered directory stack (use `cd -1`, `cd -2`, …
        # to jump to an entry). This listing used to live on `cd --`.
        if [[ $1 == "-" ]]; then
            dirs -v
            return 0
        fi

        # `cd --` is the standard end-of-options marker: everything after it
        # is a path, even if it starts with '-'. `cd --` on its own goes to
        # $HOME. (Tools like `bm` rely on this `cd -- <path>` form.)
        local -i end_opts=0
        if [[ $1 == "--" ]]; then
            end_opts=1
            shift
        fi

        the_new_dir=$1
        [[ -z $1 ]] && the_new_dir=$HOME

        if [[ $end_opts -eq 0 && ${the_new_dir:0:1} == '-' ]]; then
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

        # A path that still begins with '-' can only have arrived via
        # `cd -- <path>`; anchor it with './' so pushd reads it as a directory.
        [[ ${the_new_dir:0:1} == '-' ]] && the_new_dir="./${the_new_dir}"

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

# load pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# load rvm
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
modpath -q "$HOME/.rvm/bin"


nguard() {
    until eval $@; do
        echo "guard: zero exit status, rerunning..."
        sleep 1
    done
}

guard() {
    until eval $@; do
        echo "guard: nonzero exit status, rerunning..."
        sleep 1
    done
}

cl() {
    cd $@ && l
}

# Enable bm bookmark manager https://www.npmjs.com/package/bookmark
# alias bm="source bm"  # disabled by bookmark-cli-ng

# Enable extensions in the 'pass' command
export PASSWORD_STORE_ENABLE_EXTENSIONS=true

# SLURM setup
export SACCT_FORMAT="JobID%-20,JobName%-49,State,Elapsed,ExitCode,AllocTRES%-32"
export SQUEUE_FORMAT2="jobarrayid:20,name:50,statecompact:4,timeused:10 ,reasonlist:20 ,nice:6 ,priority:4"

# Exit trap
trap "echo bash exiting" EXIT

# Prepend personal bin dirs to the front of PATH (after pyenv/nvm/rvm have
# prepended theirs) so wrapper scripts there win over the real binaries (e.g.
# the claude --remote wrapper beats ~/.local/bin/claude). modpath -n 1 inserts
# at position 1, but it's idempotent (won't MOVE an entry already in PATH) and
# bashrc is sourced more than once, so delete any existing entry first, then
# re-add at the front. Listed in reverse so the resulting front order is
# conf.d/bin : bashrc.d/bin : bin (each -n 1 pushes the previous one back).
for _d in ~/bin ~/bashrc.d/bin ~/conf.d/bin; do
    modpath -q -d "$_d" > /dev/null 2> /dev/null
    modpath -q -n 1 "$_d"
done
unset _d

# bookmark-cli-ng
[ -f "$HOME/.local/share/bookmark-cli-ng/bm.bash" ] && source "$HOME/.local/share/bookmark-cli-ng/bm.bash"
