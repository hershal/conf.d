# modpath.sh
#
# $Id: modpath.sh,v 1.5 2004/10/08 19:07:41 steved Exp $
# $Revision: 1.5 $
#
# REVISIONS:
# 06/00/03 (steved) bourne shell wrapper for original modpath
#
# NB: This script must be sourced from the shell; it is not a stand-alone
#     command that can be executed.  If you want to use modpath within
#     your own shell scripts, you need to have the modpath alias/function,
#     or mimic its behavior e.g.:
#
#       modpath () 
#       { 
#           modpathargs=${@+"$@"};
#           . $EC_ENV_ROOT/bin/modpath.sh;
#           unset modpathargs
#       }                                     
#       modpath -f -q /new/path/bin
#
############################################################################

# make original modpath output to file
tmpfile=/tmp/modpath.sh.$$
modpathargs="-o $tmpfile $modpathargs"

# move to environment for bridge to csh
# (modpath="$modpathargs"; export modpath; /bin/csh -f $EC_ENV_ROOT/bin/modpath)
(modpath="$modpathargs"; export modpath; /bin/tcsh -f $configs/modpath)

# if modpath was successful, use the file
if [ $? = 0 -a ! -z $tmpfile ]; then
  . $tmpfile
  /bin/rm -f $tmpfile
fi

# clean up
unset tmpfile

#modpath is a function in parent, don't clear it
#unset modpath export modpath
