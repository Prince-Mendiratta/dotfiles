#!/usr/bin/env bash
# macOS-specific installation. Mirrors the original install.sh behavior.

macos_main() {
  if ! has brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  log "Installing CLI tools..."
  brew install eza fnm stow mosh fzf

  # iTerm2 (macOS only)
  if [[ ! -d "/Applications/iTerm.app" ]]; then
    log "Installing iTerm2..."
    brew install --cask iterm2
  fi

  # Nerd Font: needed for `eza --icons` and prompt glyphs. Installed to
  # ~/Library/Fonts; install_iterm_prefs points the default profile at it.
  if ! ls "$HOME/Library/Fonts"/MesloLGSNerdFont-Regular.* >/dev/null 2>&1 \
     && ! ls /Library/Fonts/MesloLGSNerdFont-Regular.* >/dev/null 2>&1; then
    log "Installing MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font
  fi

  stow_pkgs zsh
  install_zimfw

  install_iterm_prefs

  # Opt-in: screenshot -> remote-dev auto-uploader (see bin/shot-watch).
  [[ "${INSTALL_SHOT_WATCH:-0}" == "1" ]] && install_shot_watch

  create_secrets

  printf '\n\033[1;32mDone!\033[0m Open a new terminal tab to apply changes.\n'
}

# iTerm2 preferences.
#
# Default: non-destructive. Backs up your current prefs, merges a whitelist of
# global settings from the repo plist (see lib/iterm_merge_prefs.py), and adds
# the repo's profiles (tmux, Remote) as Dynamic Profiles that inherit from YOUR
# "Default" profile. Your existing profiles are left untouched.
#
# It also switches the default profile's font to the Nerd Font (keeping your
# size). Set ITERM_KEEP_FONT=1 to leave your font alone.
#
# ITERM_FULL_IMPORT=1 restores the old behavior: replace ALL iTerm prefs
# (including profiles) with iterm/com.googlecode.iterm2.plist. The plist's
# home-directory paths are rewritten to this machine's $HOME on the way in.
ITERM_NERD_FONT="MesloLGSNF-Regular"

# `ps` rather than `pgrep`: pgrep can miss GUI apps from sandboxed shells.
_iterm_running() {
  ps -axo comm= | grep '/iTerm\.app/Contents/MacOS/iTerm2$' >/dev/null  # not -q: SIGPIPE + pipefail
}

install_iterm_prefs() {
  local plist="$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist"
  local dp_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  local backup="$HOME/.iterm2-prefs-backup-$(date +%Y%m%d-%H%M%S).plist"

  if defaults export com.googlecode.iterm2 "$backup" 2>/dev/null; then
    info "Backed up current iTerm2 prefs -> $backup"
  fi

  mkdir -p "$dp_dir"

  if [[ "${ITERM_FULL_IMPORT:-0}" == "1" ]]; then
    log "Importing iTerm2 preferences (full replace)..."
    # The plist was exported on another machine: point its absolute home paths
    # at this user's $HOME and its font at the Nerd Font installed above.
    local tmp
    tmp="$(mktemp -t iterm-prefs).plist"
    plutil -convert xml1 -o "$tmp" "$plist"
    sed -i '' \
      -e "s#/Users/[^/<]*#${HOME}#g" \
      -e "s#MesloLGS-NF-Regular#${ITERM_NERD_FONT}#g" \
      "$tmp"
    defaults import com.googlecode.iterm2 "$tmp"
    rm -f "$tmp"
    # The plist already contains the tmux profile; only Remote is dynamic.
    cp "$DOTFILES_DIR/iterm/remote.json" "$dp_dir/remote.json"
    return
  fi

  if [[ -f "$plist" ]]; then
    log "Merging iTerm2 global preferences..."
    /usr/bin/python3 "$DOTFILES_DIR/lib/iterm_merge_prefs.py" "$plist"

    if [[ "${ITERM_KEEP_FONT:-0}" != "1" ]]; then
      local font_cmd=(/usr/bin/python3 "$DOTFILES_DIR/lib/iterm_merge_prefs.py" "$plist" --font "$ITERM_NERD_FONT")
      if _iterm_running; then
        # A running iTerm rewrites its profiles from memory, clobbering any
        # profile edit made via `defaults`. Apply the font once it quits.
        log "iTerm2 is running: the Nerd Font will be applied when you quit it (⌘Q)."
        nohup bash -c "$(declare -f _iterm_running)"'; while _iterm_running; do sleep 1; done; sleep 1; "$@"' _ "${font_cmd[@]}" \
          >/tmp/dotfiles-iterm-font.log 2>&1 &
        disown
      else
        "${font_cmd[@]}"
      fi
    fi
  fi

  # NOTE: iTerm does not follow symlinks in this dir, so copy the files in
  # (re-run install after editing iterm/*.json).
  log "Installing iTerm2 dynamic profiles (tmux, Remote)..."
  cp "$DOTFILES_DIR/iterm/remote.json" "$dp_dir/remote.json"
  cp "$DOTFILES_DIR/iterm/tmux.json" "$dp_dir/tmux.json"
}

# Render launchd/com.prince.shot-watch.plist for this machine and (re)load it.
install_shot_watch() {
  local label="com.prince.shot-watch"
  local agent="$HOME/Library/LaunchAgents/${label}.plist"

  log "Installing shot-watch launchd agent..."
  brew install fswatch
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s#__DOTFILES_DIR__#${DOTFILES_DIR}#g" -e "s#__HOME__#${HOME}#g" \
    "$DOTFILES_DIR/launchd/${label}.plist" > "$agent"
  launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$agent"
  info "Loaded $agent (logs: /tmp/shot-watch*.log)"
}
