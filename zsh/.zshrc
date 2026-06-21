# Uncomment to monitor zsh performance. uncomment bottomost also to see the results.
# zmodload zsh/zprof

# ============================================================================
# ZIM FRAMEWORK CONFIGURATION
# ============================================================================
ZIM_COMPINIT_FLAGS="-C"

# -----------------
# Zsh configuration
# -----------------

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# --------------------
# Module configuration
# --------------------

# zsh-autosuggestions
# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# zsh-syntax-highlighting
# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh install
fi

# Load zsh-defer first (guard for fresh installs where modules aren't downloaded yet)
if [[ -e ${ZIM_HOME}/modules/zsh-defer/zsh-defer.plugin.zsh ]]; then
  source ${ZIM_HOME}/modules/zsh-defer/zsh-defer.plugin.zsh
else
  function zsh-defer() { "$@" }
fi

# ============================================================================
# SELECTIVE MODULE LOADING - Load critical modules immediately
# ============================================================================
skip_defer=(environment utility input termtitle git duration-info git-info asciiship completion)

for zline in ${(f)"$(<$ZIM_HOME/init.zsh)"}; do
  if [[ $zline == source* ]]; then
    skip_source=0
    for skip in "${skip_defer[@]}"; do
      if [[ $zline == *"/modules/$skip/"* ]]; then
        skip_source=1
        break
      fi
    done
    if [[ $skip_source -eq 0 ]]; then
      zsh-defer -c "${zline}"
    else
      eval "${zline}"
    fi
  else
    eval "${zline}"
  fi
done

# ============================================================================
# POST-INIT - Defer key bindings
# ============================================================================
zsh-defer -c '
zmodload -F zsh/terminfo +p:terminfo
for key ("^[[A" "^P" ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ("^[[B" "^N" ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ("k") bindkey -M vicmd ${key} history-substring-search-up
for key ("j") bindkey -M vicmd ${key} history-substring-search-down
bindkey "^[[1;3D" backward-word # Alt + Left
bindkey "^[[1;3C" forward-word  # Alt + Right
unset key
'

# ============================================================================
# GIT-INFO CONFIGURATION
# ============================================================================
zstyle ':zim:git-info' verbose 'yes'
zstyle ':zim:git-info:branch'    format '%F{green}%b%f'
zstyle ':zim:git-info:indexed'   format ' %F{green}+%i%f'
zstyle ':zim:git-info:unindexed' format ' %F{yellow}!%I%f'
zstyle ':zim:git-info:untracked' format ' %F{blue}?%u%f'
zstyle ':zim:git-info:stashed'   format ' %F{cyan}*%S%f'
zstyle ':zim:git-info:ahead'     format ' %F{green}⇡%A%f'
zstyle ':zim:git-info:behind'    format ' %F{red}⇣%B%f'
zstyle ':zim:git-info:action'    format ' %F{yellow}(%s)%f'
zstyle ':zim:git-info:keys' format 'prompt' ' on %b%i%I%u%S%A%B%s'


# ============================================================================
# SHELL OPTIONS & SETTINGS
# ============================================================================
export LANG='en_US.UTF-8'

# mosh: always show predictive local echo (instant typing over high-latency links)
export MOSH_PREDICTION_DISPLAY=always

# History
HISTSIZE=50000
SAVEHIST=10000
HISTFILE=~/.zshistory
setopt HIST_IGNORE_ALL_DUPS

# Completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select


# ============================================================================
# KEY BINDINGS
# ============================================================================
bindkey '^R' history-incremental-search-backward
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search


# ============================================================================
# ALIASES
# ============================================================================

# General
alias ls='eza --icons --git'
alias ll='eza --icons --git -l'
alias la='eza --icons --git -la'
alias lt='eza --icons --git --tree'
alias cls='clear'
alias ..='cd ..'

# Directory navigation
alias st='cd ~/Documents/startup'
alias ct='cd ~/Documents/startup/clients'
alias ws='cd ~/Documents/startup/ws'

# New tmux window in the CURRENT dir. Needed under iTerm tmux -CC, where Cmd-T
# opens in $HOME and the Ctrl-b prefix is disabled by the integration.
alias nw='tmux neww -c "$PWD"'

# Git
alias commit='git commit -s -S -a -m'
alias checkout='git checkout'
alias push='git push origin'
alias pull='git pull'
alias branch='git branch'
alias status='git status'
alias add='git add'

# Development
alias build="run build"
alias dev="run dev"
alias yd="yarn start:dev"


# ============================================================================
# PATH & ENVIRONMENT
# ============================================================================
export PATH="$HOME/.venv/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"

# macOS-specific paths (Homebrew libpq, Docker Desktop)
if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
  export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"
fi

# Google Cloud SDK
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
fi


# ============================================================================
# FNM (Fast Node Manager)
# ============================================================================
# Do NOT cache `fnm env` output: each run mints a per-process, ephemeral
# multishell dir under /run/.../fnm_multishells/<pid> that dies with the shell,
# so a cached snapshot points at a dead PATH in later sessions. Eval it fresh.
if (( ${+commands[fnm]} )); then
  eval "$(fnm env --use-on-cd)"
fi


# ============================================================================
# TOOL INTEGRATIONS (cross-platform, guarded by availability)
# ============================================================================
# Bun
if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
fi

# zoxide — smarter cd (provides `z`). Deferred to keep startup fast.
if (( ${+commands[zoxide]} )); then
  zsh-defer -c 'eval "$(zoxide init zsh)"'
fi

# fzf — key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) + completion.
# Newer fzf (macOS/brew) ships `fzf --zsh`; Debian/Ubuntu's older fzf uses files.
if (( ${+commands[fzf]} )); then
  if fzf --zsh &>/dev/null; then
    source <(fzf --zsh)
  else
    for _f in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/fzf/completion.zsh; do
      [[ -r $_f ]] && source "$_f"
    done
    unset _f
  fi
fi


# ============================================================================
# CURSOR REMOTE CLI (remote hosts only)
# ============================================================================
# On a box reached via Cursor Remote-SSH, `cursor .` opens the folder in the
# connected local Cursor window. Two snags this works around: the remote `cursor`
# CLI isn't on PATH, and our persistent mosh/tmux shells don't inherit Cursor's
# $VSCODE_IPC_HOOK_CLI. The live IPC socket also isn't reliably the newest by
# mtime (globbing sockets picks stale ones), so we read the hook straight from a
# running cursor-server process each call. Guarded on the remote-cli binary
# existing, so on macOS this is skipped and the real Cursor CLI on PATH is used.
_cur_cli=(~/.cursor-server/bin/*/*/bin/remote-cli/cursor(N))
if (( $#_cur_cli )); then
  cursor() {
    local cli hook pid
    cli=( ~/.cursor-server/bin/*/*/bin/remote-cli/cursor(Nom) )
    (( $#cli )) || { print -u2 "cursor: remote CLI not found (~/.cursor-server)"; return 1; }
    for pid in ${(f)"$(pgrep -f cursor-server 2>/dev/null)"}; do
      hook=$(tr '\0' '\n' < /proc/$pid/environ 2>/dev/null | grep -m1 '^VSCODE_IPC_HOOK_CLI=')
      [[ -n $hook ]] && break
    done
    [[ -n $hook ]] || { print -u2 "cursor: no live Cursor Remote-SSH window connected to this host"; return 1; }
    VSCODE_IPC_HOOK_CLI=${hook#*=} ${cli[1]} "$@"
  }
fi
unset _cur_cli

# ============================================================================
# TERMINAL CWD REPORTING (OSC 7)
# ============================================================================
# Tell the terminal which directory each shell is in. Lets iTerm2 open a new
# tab/window in the SAME directory — including Cmd-T over a tmux -CC session,
# where iTerm otherwise can't know the remote cwd. Harmless where unsupported.
_osc7_cwd() { printf '\e]7;file://%s%s\e\\' "${HOST:-${HOSTNAME:-$(hostname)}}" "$PWD"; }
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _osc7_cwd
_osc7_cwd   # emit once for the starting directory

# ============================================================================
# SECRETS & LOCAL OVERRIDES
# ============================================================================
# ~/.secrets  — API keys and tokens (gitignored, not in this repo)
# ~/.zshrc.local — machine-specific overrides (gitignored, not in this repo)
[[ -f ~/.secrets ]] && source ~/.secrets
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Uncomment to monitor zsh performance. Uncomment the topmost line also to see the results.
# zprof

# Refresh local SSH host inventory from the iCloud-synced source.
# (We keep a *local* copy because Cursor/VS Code's ssh can't read iCloud Drive — TCC.)
ssh-hosts-sync() {
  local src="$HOME/Library/Mobile Documents/com~apple~CloudDocs/dotfiles/ssh-config"
  cp "$src" "$HOME/.ssh/icloud-hosts" && chmod 644 "$HOME/.ssh/icloud-hosts" \
    && echo "Synced ~/.ssh/icloud-hosts from iCloud."
}

alias gam="/home/prince/bin/gam7/gam"
