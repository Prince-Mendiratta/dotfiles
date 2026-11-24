# dotfiles

Shell + dev-environment setup for macOS and Ubuntu Linux. Manages:

- **Zsh** — shell config (Zim framework, aliases, key bindings) — both OSes
- **iTerm2** — terminal preferences — macOS only
- **tmux, Neovim, git** — config + tooling — Linux servers (full remote-dev setup)

`install.sh` detects the OS and dispatches to `lib/macos.sh` or `lib/linux.sh`:
- **macOS** — a lightweight setup (Homebrew, `eza`/`fnm`/`stow`, iTerm2) — unchanged from before.
- **Ubuntu** — a thorough remote-dev server: Docker, Bun, modern CLI tools, Neovim + kickstart config, Claude Code, and git commit signing.

## Fresh macOS setup

### 1. Clone the repo

```zsh
git clone git@github.com:Prince-Mendiratta/dotfiles.git ~/dotfiles
```

### 2. Run the install script

```zsh
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

This will:
- Install [Homebrew](https://brew.sh) if missing
- Install `eza`, `fnm`, `stow`, `mosh`, `fzf`
- Install the [MesloLGS Nerd Font](https://www.nerdfonts.com/) (needed for `eza --icons` and prompt glyphs)
- Symlink `~/.zshrc`, `~/.zimrc` and `~/.zprofile` via stow (existing files are backed up to `*.pre-dotfiles`)
- Download and install [zimfw](https://zimfw.sh) and all Zim modules
- Set up iTerm2 **without touching your existing profiles** (see below)
- Create a `~/.secrets` placeholder for API keys

#### iTerm2

By default the installer is non-destructive:

- Backs up your current prefs to `~/.iterm2-prefs-backup-<timestamp>.plist`
- Merges a whitelist of global settings from `iterm/com.googlecode.iterm2.plist`
  (tmux integration, Shift+Enter → newline, global hotkeys, trackpad gestures) —
  see `lib/iterm_merge_prefs.py`
- Adds the **tmux** and **Remote** profiles as [Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html)
  that inherit from *your* `Default` profile
- Switches your default profile's font to `MesloLGSNF-Regular` (keeping its size).
  If iTerm2 is running (e.g. you ran the installer from it), this is applied
  automatically once you quit iTerm2 (⌘Q), since a running iTerm overwrites
  profile edits.

| Env var | Effect |
|---|---|
| `ITERM_KEEP_FONT=1` | Don't change the default profile's font |
| `ITERM_FULL_IMPORT=1` | Old behavior: replace **all** iTerm2 prefs and profiles with the repo plist (home paths are rewritten to your `$HOME`) |
| `INSTALL_SHOT_WATCH=1` | Also install the `shot-watch` launchd agent (screenshot → remote-dev uploader) |

`bin/shot-watch` / `bin/shot-clip` default to the `remote-dev` host from your
`~/.ssh/config` and its `User`; override with `SHOT_REMOTE_HOST`,
`SHOT_REMOTE_USER`, `SHOT_REMOTE_DIR`.

### 3. Fill in your secrets

```zsh
vim ~/.secrets
```

Add your API keys (Anthropic, Azure, Gemini, etc). This file is gitignored and never committed.

### 4. Machine-specific config (optional)

For anything that differs between machines (work vs personal paths, one-off env vars):

```zsh
vim ~/.zshrc.local
```

This file is gitignored and sourced at the end of `.zshrc`.

### 5. Restart your terminal

---

## Fresh Ubuntu 24 server setup

SSH into the server (you'll need `sudo`), then:

### 1. Clone the repo

```bash
git clone https://github.com/Prince-Mendiratta/dotfiles.git ~/dotfiles
```

### 2. Run the install script

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

This installs a full remote-dev environment:

- **Shell:** `zsh` + zimfw, set as the default shell; `eza`, `stow`
- **Runtimes:** `fnm` + a Node LTS, `bun`, plus `build-essential` for native builds
- **Docker:** Engine + Compose + buildx (official repo), with your user added to the
  `docker` group so it runs without `sudo`
- **CLI tools:** `ripgrep`, `fd`, `bat`, `fzf`, `jq`, `zoxide`, `git-delta`, `gh`, `mosh`, `tmux`
- **Neovim:** latest stable (from the official release), with a
  [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)-based config tuned for JS/TS
- **Claude Code:** installed via the official native installer (`claude.ai/install.sh`), independent of Node
- **MCP servers** registered at user scope (available in any project):
  - **Context7** — live, version-correct library docs
  - **Playwright** — browser automation (Chromium auto-installed)
- **Agent sandboxing:** `devcontainer` CLI for running risky agent operations in disposable containers (`devcontainer up` + `devcontainer exec claude` per project)
- **Configs:** `~/.zshrc`, `~/.zimrc`, `~/.tmux.conf`, `~/.config/nvim`, `~/.gitconfig` (stowed)
- **Git signing:** generates `~/.ssh/id_ed25519`, writes `allowed_signers`, configures SSH commit signing

> **Identity prompt (asked first):** The script asks "Are you Prince Mendiratta? [Y/n]". Press Enter to use the defaults; answer `n` to enter your own name + email. For non-interactive runs, set `GIT_NAME` and `GIT_EMAIL` env vars and the prompt is skipped. Your identity is written to `~/.gitconfig.local` (machine-specific, not in the repo).
- **Secrets:** creates a `~/.secrets` placeholder

iTerm2 steps are skipped on Linux. The script is idempotent — safe to re-run.

> `fd`/`bat` are installed as Ubuntu's `fdfind`/`batcat` and shimmed to the
> canonical names in `~/.local/bin`.

### 3. Apply changes

The script prints next steps when it finishes:

1. **Log out and back in** (for the `docker` group and default-shell change), or `exec zsh` for the current session.
2. **Add the printed SSH key to GitHub** as a *Signing* key (Settings → SSH and GPG keys) so signed commits show as Verified.
3. **Fill in `~/.secrets`** with your API keys (and `~/.zshrc.local` for machine-specific overrides).
4. **For mosh**, open UDP `60000-61000` on the server firewall.

On first launch, Neovim will bootstrap its plugins and Mason will install the JS/TS language servers (`ts_ls`, `eslint`) and `prettierd`.

### Claude Code multi-line input

`tmux.conf` ships with the official Anthropic config (`extended-keys`, `allow-passthrough`) so **Shift+Enter** inserts a newline inside tmux instead of submitting. Per-terminal notes ([docs](https://code.claude.com/docs/en/terminal-config)):

| Terminal | Shift+Enter |
|---|---|
| iTerm2, WezTerm, Ghostty, Kitty, Warp, Apple Terminal | Works natively, no setup |
| VS Code / Cursor Remote-SSH | Run `/terminal-setup` once inside Claude Code |
| **Termius** | Not supported — use `Ctrl+J` or `\` then Enter |

`Ctrl+J` and `\<Enter>` work in **every** terminal as a fallback with no setup.

---

## Structure

```
dotfiles/
├── install.sh      # entry point: detects OS, dispatches
├── lib/
│   ├── common.sh   # shared helpers + steps (stow, zimfw, secrets)
│   ├── macos.sh    # macOS install (brew, fonts, iTerm2)
│   ├── iterm_merge_prefs.py  # non-destructive iTerm2 prefs merge
│   └── linux.sh    # Ubuntu install (docker, bun, CLI tools, neovim, ...)
├── zsh/
│   ├── .zshrc      # main shell config (symlinked to ~/.zshrc)
│   ├── .zimrc      # Zim module list (symlinked to ~/.zimrc)
│   └── .zprofile   # brew shellenv (macOS)
├── tmux/
│   └── .tmux.conf              # tmux config (Linux)
├── nvim/
│   └── .config/nvim/init.lua   # Neovim / kickstart config (Linux)
├── git/
│   └── .gitconfig              # git identity + SSH signing + delta (Linux)
├── iterm/
│   ├── com.googlecode.iterm2.plist   # iTerm2 global prefs source (macOS)
│   ├── tmux.json                     # "tmux" dynamic profile
│   └── remote.json                   # "Remote" dynamic profile
├── bin/            # remote-connect, shot-watch, shot-clip
└── launchd/        # shot-watch agent template (opt-in)
```

Stow packages are applied per-OS: macOS stows only `zsh`; Linux stows `zsh git tmux nvim`.

## Adding new config

1. Put the file in the right package dir (e.g. `tmux/`)
2. Run `stow tmux` from `~/dotfiles` to create the symlink
3. Commit

## What's NOT in this repo

| File | Where it lives | Why |
|---|---|---|
| `~/.secrets` | local only | API keys — never commit |
| `~/.zshrc.local` | local only | machine-specific overrides |
| `~/.gitconfig.local` | local only | machine-specific git overrides (optional) |
| `~/.zshistory` | local only | shell history |
