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

  stow_pkgs zsh
  install_zimfw

  # iTerm2 preferences
  if [[ -f "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist" ]]; then
    log "Importing iTerm2 preferences..."
    defaults import com.googlecode.iterm2 "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist"
  fi

  # iTerm2 dynamic profiles. NOTE: iTerm does not follow symlinks in this dir,
  # so we copy the file in (re-run install after editing iterm/remote.json).
  if [[ -f "$DOTFILES_DIR/iterm/remote.json" ]]; then
    log "Installing iTerm2 dynamic profiles..."
    local dp_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$dp_dir"
    cp "$DOTFILES_DIR/iterm/remote.json" "$dp_dir/remote.json"
  fi

  create_secrets

  printf '\n\033[1;32mDone!\033[0m Open a new terminal tab to apply changes.\n'
}
