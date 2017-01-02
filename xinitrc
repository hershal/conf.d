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

xset r rate 200 80
xset s off &
xset dpms 600 0 0 &

# Set the preferred keyboard map:
# Compose is the Menu button
setxkbmap -option compose:menu
# Caps is the Ctrl buton
setxkbmap -option ctrl:nocaps
# xrandr --output DVI-1 --right-of HDMI-0 --mode 1920x1200
# xrandr --output DVI-0 --right-of DVI-1 --mode 1920x1200

export BSPWM_TREE=/tmp/bspwm-tree.json
export BSPWM_HISTORY=/tmp/bspwm-history.txt
export BSPWM_STACK=/tmp/bspwm-stack.txt

# Hang point
gnome-terminal &
emacs &
sxhkd &
exec bspwm
