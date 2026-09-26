#!/bin/bash
# Raycast Script Command — bind this to a global hotkey in Raycast so the
# clipboard-screenshot flow is:  ⌘⌃⇧4 (region → clipboard)  →  hotkey  →  ⌘V
# the remote path into Claude Code on remote-dev.
#
# It is a thin shim over ~/dotfiles/bin/shot-clip (which holds all the real
# logic and is reusable from the CLI). Add ~/dotfiles/raycast as a Script
# Commands directory in Raycast, then assign a hotkey to "Upload clipboard
# screenshot".
#
# @raycast.schemaVersion 1
# @raycast.title Upload clipboard screenshot
# @raycast.mode compact
#
# @raycast.icon 📸
# @raycast.packageName Screenshots
# @raycast.description Upload the screenshot on the clipboard to remote-dev:~/shots and copy the remote path back to the clipboard.
# @raycast.author prince

exec "$HOME/dotfiles/bin/shot-clip"
