#!/usr/bin/env bash
set -e

echo "==> Installing dotfiles..."

OS="$(uname -s)"
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============================================================================
# Package installation (OS-specific)
# ============================================================================
install_packages_macos() {
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  echo "==> Installing CLI tools..."
  brew install eza fnm stow

  # iTerm2 (macOS only)
  if [[ ! -d "/Applications/iTerm.app" ]]; then
    echo "==> Installing iTerm2..."
    brew install --cask iterm2
  fi
}

install_packages_linux() {
  # Use sudo only when not already root (so this works in both cases).
  local SUDO=""
  [[ $EUID -ne 0 ]] && SUDO="sudo"

  echo "==> Installing CLI tools via apt..."
  $SUDO apt update
  $SUDO apt install -y zsh git curl unzip stow eza

  if ! command -v fnm &>/dev/null; then
    echo "==> Installing fnm..."
    # --skip-shell: don't touch shell rc files (.zshrc handles fnm itself).
    # --install-dir: drop the binary in ~/.local/bin, already on PATH.
    curl -fsSL https://fnm.vercel.app/install | bash -s -- \
      --install-dir "$HOME/.local/bin" --skip-shell
  fi
}

# ============================================================================
# Default shell -> zsh (Linux; macOS already defaults to zsh)
# ============================================================================
set_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
    echo "==> Setting default shell to zsh..."
    chsh -s "$zsh_path" || echo "   Could not change shell automatically; run: chsh -s $zsh_path"
  fi
}

# ============================================================================
# Stow dotfiles
# ============================================================================
stow_dotfiles() {
  echo "==> Symlinking dotfiles with stow..."
  cd "$DOTFILES_DIR"

  # Remove existing files that would conflict
  [[ -f ~/.zshrc    && ! -L ~/.zshrc    ]] && mv ~/.zshrc    ~/.zshrc.pre-dotfiles
  [[ -f ~/.zimrc    && ! -L ~/.zimrc    ]] && mv ~/.zimrc    ~/.zimrc.pre-dotfiles
  [[ -f ~/.zprofile && ! -L ~/.zprofile ]] && mv ~/.zprofile ~/.zprofile.pre-dotfiles

  stow zsh
}

# ============================================================================
# Zim framework (installs on first shell open, but trigger it now)
# ============================================================================
install_zimfw() {
  local ZIM_HOME="${HOME}/.zim"
  if [[ ! -e "${ZIM_HOME}/zimfw.zsh" ]]; then
    echo "==> Downloading zimfw..."
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
    # zimfw reads ZIM_HOME from the environment; export it for the subprocess.
    ZIM_HOME="${ZIM_HOME}" zsh "${ZIM_HOME}/zimfw.zsh" install
  fi
}

# ============================================================================
# iTerm2 preferences (macOS only)
# ============================================================================
import_iterm2_prefs() {
  if [[ -f "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist" ]]; then
    echo "==> Importing iTerm2 preferences..."
    defaults import com.googlecode.iterm2 "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist"
  fi
}

# ============================================================================
# Secrets placeholder
# ============================================================================
create_secrets() {
  if [[ ! -f ~/.secrets ]]; then
    echo "==> Creating ~/.secrets placeholder..."
    cat > ~/.secrets <<'SECRETS'
# API keys and tokens — fill these in, never commit this file

# Anthropic / Claude
# export ANTHROPIC_AUTH_TOKEN=
# export ANTHROPIC_BASE_URL=
# export ANTHROPIC_MODEL=
# export ANTHROPIC_DEFAULT_HAIKU_MODEL=

# Azure OpenAI
# export AZURE_OPENAI_API_KEY=

# Google Gemini
# export GEMINI_API_KEY=
# export GOOGLE_GEMINI_BASE_URL=
SECRETS
    echo "   Edit ~/.secrets and fill in your API keys."
  fi
}

# ============================================================================
# Run
# ============================================================================
case "$OS" in
  Darwin)
    install_packages_macos
    stow_dotfiles
    install_zimfw
    import_iterm2_prefs
    create_secrets
    echo ""
    echo "Done! Open a new terminal tab to apply changes."
    ;;
  Linux)
    install_packages_linux
    stow_dotfiles
    install_zimfw
    set_default_shell_zsh
    create_secrets
    echo ""
    echo "Done! Log out and back in (or run 'exec zsh') to apply changes."
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac
