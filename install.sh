#!/usr/bin/env zsh
set -e

echo "==> Installing dotfiles..."

# ============================================================================
# Homebrew
# ============================================================================
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ============================================================================
# CLI tools
# ============================================================================
echo "==> Installing CLI tools..."
brew install eza fnm stow

# ============================================================================
# Stow dotfiles
# ============================================================================
echo "==> Symlinking dotfiles with stow..."
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# Remove existing files that would conflict
[[ -f ~/.zshrc && ! -L ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.pre-dotfiles
[[ -f ~/.zimrc && ! -L ~/.zimrc ]] && mv ~/.zimrc ~/.zimrc.pre-dotfiles

stow zsh

# ============================================================================
# Zim framework (installs on first shell open, but trigger it now)
# ============================================================================
ZIM_HOME="${HOME}/.zim"
if [[ ! -e "${ZIM_HOME}/zimfw.zsh" ]]; then
  echo "==> Downloading zimfw..."
  curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  zsh "${ZIM_HOME}/zimfw.zsh" install
fi

# ============================================================================
# iTerm2 preferences
# ============================================================================
if [[ -f "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist" ]]; then
  echo "==> Importing iTerm2 preferences..."
  defaults import com.googlecode.iterm2 "$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist"
fi

# ============================================================================
# Secrets placeholder
# ============================================================================
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

echo ""
echo "Done! Open a new terminal tab to apply changes."
