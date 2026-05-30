# tmux: Zero to Hero (a guide for a friend)

Hey! You just got SSH'd into a server that has tmux installed, and you've never used tmux before. This guide will get you from "wat" to "I look like I know what I'm doing" in about 15 minutes. Bookmark it, refer back to it.

---

## What problem does tmux solve?

When you SSH into a server and run something — say, `npm run build` or a long script or your editor — that thing lives inside *the SSH connection itself*. The moment your WiFi blips or you close your laptop, the server kills your shell and everything in it. All progress lost.

**tmux fixes that.** It's a session manager that runs **on the server**. Your shell, your editor, your long-running commands — they all live inside tmux. When you disconnect, tmux keeps running. You SSH back in, attach to your session, and you're back exactly where you were. Like the connection never dropped.

It also gives you split panes, multiple "tabs" (windows), and a bunch of other quality-of-life stuff once you're in.

> **mosh + tmux** is the magic combo: mosh keeps the network connection resilient; tmux keeps your server-side session alive even if mosh/SSH drops entirely. Always use both.

---

## The mental model

Three nested things:

```
session → window → pane
```

- **Session** = a workspace. Has a name. Survives disconnection. You'll usually have 1–3 of these total.
- **Window** = like a browser tab *inside* a session. Numbered starting at 1.
- **Pane** = a split *inside* a window. Like splitting your editor into two columns.

You'll spend 90% of your time in panes and windows. Sessions are the big-picture container.

---

## The prefix key

tmux owns exactly one keyboard shortcut: **`Ctrl-b`**. Everyone calls it "the prefix."

Every tmux command is `Ctrl-b` followed by another key. You press them **in sequence**, not together — press `Ctrl-b`, release, then press the next key.

In this guide, `Ctrl-b c` means: press `Ctrl-b`, release, press `c`.

---

## The 10-minute tour

Walk through these in order. By the end you'll have done everything you'll do 90% of the time.

### Step 1: Start your first session

```bash
tmux new -s main
```

`-s main` names the session `main`. You're now **inside** tmux. Look at the bottom of your terminal — green status bar showing `[main]` and the current window. That's how you know.

### Step 2: Detach (the magic command)

```
Ctrl-b d
```

You're back in your bare shell. But the tmux session is still **running on the server**. Anything inside it is still alive.

### Step 3: Re-attach

```bash
tmux a              # attach to most recent session
tmux a -t main      # attach by name
tmux ls             # list all sessions
```

Try it: `tmux a`. You're back exactly where you were.

> **This is the whole point of tmux.** Everything else is gravy.

### Step 4: New window (like a browser tab)

```
Ctrl-b c
```

You'll see a new number in the status bar. Cycle between windows:

```
Ctrl-b n            # next window
Ctrl-b p            # previous window
Ctrl-b 1 / 2 / 3    # jump to window N by number
```

Rename the current window:

```
Ctrl-b ,            # then type a name + Enter
```

> Your `.tmux.conf` makes windows start at 1 (not 0), and renumbers them if you close one in the middle. Saves you mental math.

### Step 5: Split into panes

```
Ctrl-b "            # split horizontally (panes stacked top/bottom)
Ctrl-b %            # split vertically (panes side by side)
```

Move between panes:

```
Ctrl-b ← / → / ↑ / ↓        # arrow keys
```

Or just click with the mouse — your `.tmux.conf` enables mouse mode.

**Zoom** the current pane to full screen:

```
Ctrl-b z            # toggle zoom
```

This is incredibly useful when you've split too much and want to focus on one pane. Press again to un-zoom.

Close a pane: type `exit` in it, or `Ctrl-b x` and confirm.

### Step 6: Scroll up (read what scrolled off)

Your terminal's normal scroll doesn't work inside tmux — tmux owns the screen. Instead, you enter **copy mode**:

```
Ctrl-b [
```

Now use:
- Arrow keys / Page Up / Page Down
- Or just scroll with your mouse wheel

Exit copy mode: press `q`.

### Step 7: Copy text

In copy mode (`Ctrl-b [`), with your `.tmux.conf`'s vi-style copy bindings:

- `v` — start a selection
- Move the cursor with arrow keys
- `y` — copy

Or just **click and drag with your mouse** — release, and it's copied to tmux's buffer.

> System clipboard bridging depends on your terminal app. Termius works out of the box; if not, use mouse selection and then `Cmd+C` in your terminal app.

---

## The killer workflow (this is why people use tmux)

1. **First time:** `tmux new -s main`
2. **Work** — open neovim, run a build, watch logs, whatever.
3. **Disconnect carelessly** — close your laptop, lose WiFi, switch from Mac to phone. Whatever.
4. **Come back later** (an hour, a day): SSH/mosh in → `tmux a` → you're back exactly where you were. Same files open. Same logs streaming. Same everything.

That's it. That's the whole reason.

---

## One-session-per-task pattern

When you're juggling multiple things, give each its own named session:

```bash
tmux new -s auth-fix       # session for one task
# ... work ...
Ctrl-b d                   # detach
tmux new -s api-redesign   # another session for another task
```

See what's running and switch between them:

```bash
tmux ls                    # list all sessions
tmux a -t auth-fix         # attach to a specific one
```

While attached, jump to another session interactively:

```
Ctrl-b s                   # session picker (arrow keys + Enter)
```

This pairs perfectly with **git worktrees**: one worktree per task, one tmux session per worktree. No conflicts, easy context-switching.

---

## Cheatsheet

All commands start with the prefix **`Ctrl-b`**, then the next key.

### Sessions

| Command | Action |
|---|---|
| `tmux new -s <name>` | New named session |
| `tmux ls` | List all sessions |
| `tmux a` | Attach to most recent |
| `tmux a -t <name>` | Attach by name |
| `tmux kill-session -t <name>` | Kill a session |
| `Ctrl-b d` | Detach (session keeps running) |
| `Ctrl-b s` | Interactive session picker |
| `Ctrl-b $` | Rename current session |

### Windows (tabs inside a session)

| Keys | Action |
|---|---|
| `Ctrl-b c` | New window |
| `Ctrl-b n` | Next window |
| `Ctrl-b p` | Previous window |
| `Ctrl-b 1`..`9` | Jump to window by number |
| `Ctrl-b ,` | Rename current window |
| `Ctrl-b w` | Window picker |
| `Ctrl-b &` | Close current window (asks confirm) |

### Panes (splits inside a window)

| Keys | Action |
|---|---|
| `Ctrl-b "` | Split horizontally (stacked) |
| `Ctrl-b %` | Split vertically (side-by-side) |
| `Ctrl-b ←/→/↑/↓` | Move between panes |
| `Ctrl-b z` | Zoom toggle (full-screen this pane) |
| `Ctrl-b x` | Close current pane |
| `Ctrl-b {` / `}` | Swap pane with previous / next |
| `Ctrl-b space` | Cycle through pane layouts |

### Copy mode (scrollback + copying)

| Keys | Action |
|---|---|
| `Ctrl-b [` | Enter copy mode |
| `v` | Start selection (vi-style) |
| `y` | Copy selection |
| `q` | Exit copy mode |
| Mouse drag | Select + copy |
| Mouse wheel | Scroll |

### Other

| Keys | Action |
|---|---|
| `Ctrl-b r` | Reload `~/.tmux.conf` (custom binding) |
| `Ctrl-b ?` | Show ALL keybindings (press `q` to exit) |
| `Ctrl-b :` | Command prompt (advanced) |

---

## Pitfalls that bite beginners

1. **Don't type `exit` to "leave" tmux.** That closes your shell *inside* the session. If it was the only shell, the session dies and you lose your work. **Always use `Ctrl-b d` to detach.**

2. **`Ctrl-b` is a real shortcut in some apps** (like Emacs back-char, or bash's "move cursor left"). Inside Claude Code or vim it's fine. If it bites you, you can remap to `Ctrl-a` later — but the default works.

3. **You're stuck and nothing's typing.** You're probably in copy mode. Press `q`.

4. **Mouse scroll only works inside tmux.** Outside tmux (bare shell), it scrolls your terminal as normal. The mode switches automatically.

5. **A "dead" session sticking around.** If you see `tmux ls` showing a session you don't want, kill it: `tmux kill-session -t <name>`. They're just processes; killing them is safe (it's the same as closing all the panes in it).

6. **You see `(attached)` next to a session name.** That just means someone's attached to it right now — usually you, from another terminal. Multiple connections to the same session is allowed (and often useful — you and a coworker can both see the same screen).

---

## First-day shortlist

If you remember nothing else, remember these eight things:

```
tmux new -s main           # start
Ctrl-b d                   # detach (NEVER type 'exit')
tmux a                     # come back

Ctrl-b c                   # new window (tab)
Ctrl-b n / p               # next/prev window
Ctrl-b "                   # split horizontal
Ctrl-b %                   # split vertical
Ctrl-b z                   # zoom current pane
```

That's the entire 80%. Drill these eight, you're operating at like senior-dev tmux level.

---

## "I broke something"

Your `.tmux.conf` (the config file) is in the repo at `tmux/.tmux.conf`. If you've edited it and want to apply changes without restarting tmux:

```
Ctrl-b r
```

If you want to nuke everything and start over:

```bash
tmux kill-server           # kills ALL tmux sessions on this machine
```

Don't worry — that doesn't kill the SSH connection, just tmux. You'll lose any unsaved work in panes, of course.

---

## Next steps (when you're ready)

- **tmux-resurrect** + **tmux-continuum** — save sessions to disk so they survive server reboots. Not installed yet; nice to add later.
- **Custom keybindings** — many people remap the prefix to `Ctrl-a` (closer to home row). Edit `tmux/.tmux.conf` and rebind.
- **Status bar customization** — the bottom bar can show CPU, time, git branch, weather. Hours of fun if you're into that.

But honestly, for 90% of your usage, the eight commands above are enough. Welcome to the cult.
