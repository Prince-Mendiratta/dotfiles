#!/usr/bin/env bash
set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

log "Installing dotfiles..."

case "$(uname -s)" in
  Darwin)
    # shellcheck source=lib/macos.sh
    source "$DOTFILES_DIR/lib/macos.sh"
    macos_main
    ;;
  Linux)
    # shellcheck source=lib/linux.sh
    source "$DOTFILES_DIR/lib/linux.sh"
    linux_main
    ;;
  *)
    die "Unsupported OS: $(uname -s)"
    ;;
esac
