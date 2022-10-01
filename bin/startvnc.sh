#!/usr/bin/env bash

tigervncserver -kill :1
tigervncserver -xstartup /usr/bin/gnome-session-classic -geometry 2880x1800 -localhost no :1
