#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi


# Start the window manager
/usr/bin/i3 & wmpid=$!

# Start misc things
xrdb ~/.Xresources &
synclient TouchpadOff=1 &
xbindkeys &
xset s off &
xset dpms 600 60 60 &
setxkbmap -option compose:menu
xautolock &

# Hang point
wait $wmpid
