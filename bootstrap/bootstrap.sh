source ~/conf.d/bootstrap/common/base.sh
source ~/conf.d/bootstrap/common/emacs.sh
source ~/conf.d/bootstrap/common/node.sh
source ~/conf.d/bootstrap/common/ruby.sh

case `uname -a` in
    *ARCH* )
        source ${configs}/bootstrap/bootstrap.linux
        source ${configs}/bootstrap/bootstrap.arch ;;
    *Linux* )
        source ${configs}/bootstrap/bootstrap.linux ;;
    *Darwin* )
        source ${configs}/bootstrap/bootstrap.osx ;;
    *Cygwin* )
        source ${configs}/bootstrap/bootstrap.cygwin ;;
esac
