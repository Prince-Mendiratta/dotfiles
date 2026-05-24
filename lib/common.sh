#!/usr/bin/env bash
# Shared helpers and OS-agnostic install steps.
# Sourced by install.sh; relies on $DOTFILES_DIR being exported.

# --- logging ---
log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { warn "$*"; exit 1; }

# --- predicates ---
has() { command -v "$1" >/dev/null 2>&1; }

# --- shared steps (used by both macOS and Linux) ---

# _backup_if_real <name> — if ~/<name> is a real file (not a symlink), move it aside.
_backup_if_real() {
  local f="$1"
  if [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]]; then
    mv "$HOME/$f" "$HOME/${f}.pre-dotfiles"
    info "Backed up existing ~/$f -> ~/${f}.pre-dotfiles"
  fi
}

# stow_pkgs <pkg>... — symlink the given stow packages from $DOTFILES_DIR into $HOME.
# Only backs up the conflicting files for the packages actually being stowed,
# and is idempotent (re-stowing existing symlinks is a no-op).
stow_pkgs() {
  log "Symlinking dotfiles with stow: $*"
  cd "$DOTFILES_DIR"

  # Ensure ~/.config exists as a real dir so stow folds at ~/.config/nvim
  # (the package symlink) rather than symlinking all of ~/.config to the repo.
  mkdir -p "$HOME/.config"

  local pkg
  for pkg in "$@"; do
    case "$pkg" in
      zsh)  _backup_if_real .zshrc; _backup_if_real .zimrc; _backup_if_real .zprofile ;;
      git)  _backup_if_real .gitconfig ;;
      tmux) _backup_if_real .tmux.conf ;;
    esac
  done

  stow "$@"
}

install_zimfw() {
  local ZIM_HOME="${HOME}/.zim"
  if [[ ! -e "${ZIM_HOME}/zimfw.zsh" ]]; then
    log "Installing zimfw..."
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
    # zimfw reads ZIM_HOME from the environment; export it for the subprocess.
    ZIM_HOME="${ZIM_HOME}" zsh "${ZIM_HOME}/zimfw.zsh" install
  fi
}

create_secrets() {
  if [[ ! -f "$HOME/.secrets" ]]; then
    log "Creating ~/.secrets placeholder..."
    cat > "$HOME/.secrets" <<'SECRETS'
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
    info "Edit ~/.secrets and fill in your API keys."
  fi
}
