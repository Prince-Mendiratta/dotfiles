# dotfiles

Minimal shell configuration for macOS and Ubuntu Linux. Manages:

- **Zsh** — shell config (Zim framework, aliases, key bindings)
- **iTerm2** — terminal preferences (macOS only)

`install.sh` detects the OS and installs accordingly: Homebrew on macOS, `apt` + the official `fnm` installer on Ubuntu.

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
- Install `eza`, `fnm`, `stow`
- Symlink `~/.zshrc` and `~/.zimrc` via stow
- Download and install [zimfw](https://zimfw.sh) and all Zim modules
- Import iTerm2 preferences
- Create a `~/.secrets` placeholder for API keys

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

This will:
- Install `zsh`, `git`, `curl`, `unzip`, `stow`, `eza` via `apt`
- Install `fnm` via its official installer (into `~/.local/bin`)
- Symlink `~/.zshrc` and `~/.zimrc` via stow
- Download and install [zimfw](https://zimfw.sh) and all Zim modules
- Set zsh as your default shell
- Create a `~/.secrets` placeholder for API keys

iTerm2 steps are skipped on Linux.

### 3. Apply changes

Log out and back in (so the default-shell change takes effect), or run `exec zsh` for the current session. Then fill in `~/.secrets` and, optionally, `~/.zshrc.local` as on macOS.

---

## Structure

```
dotfiles/
├── zsh/
│   ├── .zshrc      # main shell config (symlinked to ~/.zshrc)
│   └── .zimrc      # Zim module list (symlinked to ~/.zimrc)
└── iterm/
    └── com.googlecode.iterm2.plist   # iTerm2 preferences
```

## Adding new config

1. Put the file in the right package dir (e.g. `zsh/`)
2. Run `stow zsh` from `~/dotfiles` to create the symlink
3. Commit

## What's NOT in this repo

| File | Where it lives | Why |
|---|---|---|
| `~/.secrets` | local only | API keys — never commit |
| `~/.zshrc.local` | local only | machine-specific overrides |
| `~/.zshistory` | local only | shell history |
