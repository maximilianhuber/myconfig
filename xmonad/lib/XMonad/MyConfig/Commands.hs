-- Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
-- SPDX-License-Identifier: MIT
module XMonad.MyConfig.Commands
    where

terminalCMD       = "urxvtc"
terminalServerCMD = "urxvtd -q -f -o"
bashCMD           = "bash"
zshCMD            = "zsh"
editorCMD         = "ec"
dmenuPathCMD      = "dmenu_path"
yeganeshCMD       = "yeganesh"
passmenuCMD       = "passmenu"
firefoxCMD        = "firefox"
findCursorCMD     = "find-cursor"
xdotoolCMD        = "xdotool"
synclientCMD      = "synclient"
myautosetupCMD    = "myautosetup.pl"
xsetCMD           = "xset"
invertColorsCMD   = "xrandr-invert-colors"
-- or: "xcalib -i -a"
screenshotCMD     = "screenshot.sh"
-- or:
-- - "bash -c \"import -frame ~/screen_`date +%Y-%m-%d_%H-%M-%S`.png\"")
-- - "mkdir -p ~/_screenshots/ && scrot ~/_screenshots/screen_%Y-%m-%d_%H-%M-%S.png -d 1"
fehCMD            = "feh"
unclutterCMD      = "unclutter"
