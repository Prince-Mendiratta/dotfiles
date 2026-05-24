#!/usr/bin/env bash
# Linux (Ubuntu 24.04) installation: a thorough remote-dev setup.

# Use sudo only when not already root (works as both a sudo user and root).
SUDO=""
[[ ${EUID:-$(id -u)} -ne 0 ]] && SUDO="sudo"

ARCH="$(uname -m)"

apt_install() { $SUDO apt-get install -y --no-install-recommends "$@"; }

linux_main() {
  export DEBIAN_FRONTEND=noninteractive
  # Make ~/.local/bin tools (fnm, nvim, shims) usable within this script run.
  export PATH="$HOME/.local/bin:$PATH"

  linux_identity      # ask once, up front
  linux_apt_base
  linux_cli_shims
  linux_docker
  linux_bun
  linux_node          # Node LTS via fnm for general JS/TS dev
  linux_neovim
  linux_claude_code
  linux_git_signing

  # Linux stows the full set; macOS only stows zsh (configs differ per-OS).
  stow_pkgs zsh git tmux nvim
  install_zimfw
  linux_default_shell
  create_secrets

  linux_summary
}

# --- identity (asked once, written to ~/.gitconfig.local) -----------------

# Defaults for the primary user. Anyone else picks "n" at the prompt and
# enters their own name + email. Either can also be set via env vars
# (GIT_NAME, GIT_EMAIL) for non-interactive provisioning.
DEFAULT_GIT_NAME="Prince Mendiratta"
DEFAULT_GIT_EMAIL="prince.mendi@gmail.com"

linux_identity() {
  # If already configured (re-run), reuse what's there.
  if [[ -f "$HOME/.gitconfig.local" ]] \
     && GIT_NAME="$(git config -f "$HOME/.gitconfig.local" user.name 2>/dev/null)" \
     && GIT_EMAIL="$(git config -f "$HOME/.gitconfig.local" user.email 2>/dev/null)" \
     && [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
    export GIT_NAME GIT_EMAIL
    info "Using existing identity from ~/.gitconfig.local: $GIT_NAME <$GIT_EMAIL>"
    return
  fi

  # Env-var override skips the prompt.
  if [[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]]; then
    info "Using identity from env: $GIT_NAME <$GIT_EMAIL>"
  else
    log "Git commit identity"
    printf "    Are you %s <%s>? [Y/n] " "$DEFAULT_GIT_NAME" "$DEFAULT_GIT_EMAIL"
    local ans=""
    read -r ans || true
    case "$ans" in
      n|N|no|No|NO)
        printf "    Your full name:  "; read -r GIT_NAME
        printf "    Your git email:  "; read -r GIT_EMAIL
        ;;
      *)
        GIT_NAME="$DEFAULT_GIT_NAME"
        GIT_EMAIL="$DEFAULT_GIT_EMAIL"
        ;;
    esac
    if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
      die "Identity required (name and email). Aborting."
    fi
    export GIT_NAME GIT_EMAIL
  fi

  cat > "$HOME/.gitconfig.local" <<EOF
# Written by dotfiles install.sh — machine-specific git identity.
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF
  info "Wrote identity to ~/.gitconfig.local"
}

# --- packages -------------------------------------------------------------

linux_apt_base() {
  log "Updating apt and installing base packages + CLI tools..."
  $SUDO apt-get update
  apt_install \
    zsh git curl wget unzip ca-certificates gnupg build-essential \
    stow eza \
    ripgrep fd-find bat fzf jq zoxide git-delta gh mosh tmux

  # fnm (Node version manager) — official installer, no shell-rc edits.
  if ! has fnm; then
    log "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- \
      --install-dir "$HOME/.local/bin" --skip-shell
  fi
}

linux_cli_shims() {
  # Ubuntu ships fd as 'fdfind' and bat as 'batcat'. Expose them under the
  # canonical names (matching macOS/brew) so configs/aliases stay uniform.
  mkdir -p "$HOME/.local/bin"
  has fdfind && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  has batcat && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
}

# --- docker (rootful, usable without sudo via the docker group) -----------

linux_docker() {
  if has docker; then info "docker already installed"; return; fi
  log "Installing Docker Engine (official repo)..."

  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

  local codename
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

  $SUDO apt-get update
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Run docker without sudo: add the invoking (non-root) user to the docker group.
  local target_user="${SUDO_USER:-$USER}"
  if [[ -n "$target_user" && "$target_user" != "root" ]]; then
    $SUDO usermod -aG docker "$target_user"
    info "Added '$target_user' to the docker group (re-login required to take effect)."
  fi

  # Enable on boot + start now (no-op on systems without systemd, e.g. containers).
  $SUDO systemctl enable --now docker >/dev/null 2>&1 \
    || warn "Could not start docker via systemctl (no systemd here?). It will start on a real server."
}

# --- runtimes -------------------------------------------------------------

linux_bun() {
  if has bun; then info "bun already installed"; return; fi
  log "Installing Bun..."
  # The Bun installer appends to shell rc files. We run it BEFORE stow (so
  # ~/.zshrc is not yet our symlink) and manage bun's PATH in .zshrc ourselves.
  curl -fsSL https://bun.sh/install | bash >/dev/null
}

linux_node() {
  log "Installing Node LTS via fnm..."
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest || true
  fnm use lts-latest >/dev/null 2>&1 || true
  info "Node $(node --version 2>/dev/null || echo '?') ready."
}

linux_claude_code() {
  if has claude; then info "claude code already installed"; return; fi
  log "Installing Claude Code (native installer)..."
  # Native installer drops the binary in ~/.local/bin/claude (or similar
  # XDG path), independent of Node/fnm. Run before stow so any rc-file
  # edits don't touch the stowed ~/.zshrc symlink.
  curl -fsSL https://claude.ai/install.sh | bash
}

# --- neovim (latest stable from official release; apt's is too old) -------

linux_neovim() {
  if [[ -x "$HOME/.local/opt/nvim/bin/nvim" ]]; then info "neovim already installed"; return; fi
  log "Installing Neovim (latest stable)..."

  local asset
  case "$ARCH" in
    x86_64)  asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64) asset="nvim-linux-arm64.tar.gz" ;;
    *) warn "Unsupported arch '$ARCH' for Neovim; skipping."; return ;;
  esac

  local tmp; tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/nvim.tar.gz" \
      "https://github.com/neovim/neovim/releases/download/stable/${asset}"; then
    warn "Neovim download failed; skipping."
    rm -rf "$tmp"; return
  fi
  mkdir -p "$HOME/.local/opt/nvim"
  tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt/nvim" --strip-components=1
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  info "Neovim $("$HOME/.local/bin/nvim" --version | head -1 | awk '{print $2}') installed."
}

# --- git ssh commit signing ----------------------------------------------

linux_git_signing() {
  log "Configuring git SSH commit signing..."
  : "${GIT_EMAIL:?GIT_EMAIL must be set (linux_identity should run first)}"

  if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N "" -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" >/dev/null
    info "Generated ~/.ssh/id_ed25519 (also usable as your signing key)."
  fi

  # Trust our own key for local signature verification (git log --show-signature).
  if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    mkdir -p "$HOME/.config/git"
    printf '%s %s\n' "$GIT_EMAIL" "$(cut -d' ' -f1,2 "$HOME/.ssh/id_ed25519.pub")" \
      > "$HOME/.config/git/allowed_signers"
  fi
  # Signing prefs + key path live in the stowed git/.gitconfig;
  # user.name/user.email live in ~/.gitconfig.local (written by linux_identity).
}

# --- shell ----------------------------------------------------------------

linux_default_shell() {
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
    log "Setting default shell to zsh..."
    $SUDO chsh -s "$zsh_path" "${SUDO_USER:-$USER}" \
      || chsh -s "$zsh_path" \
      || warn "Could not change shell automatically; run: chsh -s $zsh_path"
  fi
}

linux_summary() {
  printf '\n\033[1;32mDone!\033[0m Next steps:\n'
  printf '  1. Log out and back in (for the docker group + default shell), or run: exec zsh\n'
  printf '  2. Add this key to GitHub as a *Signing* key (Settings > SSH and GPG keys):\n\n'
  [[ -f "$HOME/.ssh/id_ed25519.pub" ]] && sed 's/^/       /' "$HOME/.ssh/id_ed25519.pub"
  printf '\n  3. Fill in ~/.secrets with your API keys.\n'
  printf '  4. For mosh, open UDP 60000-61000 on the server firewall.\n'
}
