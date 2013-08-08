#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# Run each file in xinitrc.d
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# Run the Xmodmap bindings
if [ -f $HOME/.Xmodmap ]; then
    /usr/bin/xmodmap $HOME/.Xmodmap*
fi

# Run the Xresources configs
if [ -f $HOME/.Xresources ]; then
    /usr/bin/xrdb $HOME/.Xresources
fi

if [ -f $HOME/.xbindkeysrc ]; then
    /usr/bin/xbindkeys
fi

# Start the window manager
/usr/bin/i3 & wmpid=$!

# Start misc things
if [ -f /usr/bin/synclient ]; then
  synclient TouchpadOff=1 &
fi

xset r rate 200 60
xset s off &
xset dpms 600 0 0 &

# Set the preferred keyboard map: 
# Compose is the Menu button
setxkbmap -option compose:menu
# Caps is the Ctrl buton
setxkbmap -option ctrl:nocaps

# Enable the auto-locking mechanism
# with the delays set in Xresources
xautolock &

# Hang point
wait $wmpid
