source ~/conf.d/bashrc

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
