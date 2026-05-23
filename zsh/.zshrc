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
# FNM - CACHED & DEFERRED
# ============================================================================
if [[ ! -f ~/.fnm-env.zsh ]] || [[ ~/.zshrc -nt ~/.fnm-env.zsh ]]; then
  fnm env --use-on-cd >! ~/.fnm-env.zsh 2>/dev/null
fi
zsh-defer source ~/.fnm-env.zsh


# ============================================================================
# SECRETS & LOCAL OVERRIDES
# ============================================================================
# ~/.secrets  — API keys and tokens (gitignored, not in this repo)
# ~/.zshrc.local — machine-specific overrides (gitignored, not in this repo)
[[ -f ~/.secrets ]] && source ~/.secrets
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Uncomment to monitor zsh performance. Uncomment the topmost line also to see the results.
# zprof

