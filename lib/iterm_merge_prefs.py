#!/usr/bin/env python3
"""Merge selected global iTerm2 preferences from the repo plist into the live prefs.

Unlike `defaults import`, this never touches profiles ("New Bookmarks", the
default-profile GUID) or machine-specific state (window frames, update feeds,
version stamps). Profiles are shipped separately as Dynamic Profiles
(iterm/*.json) that inherit from whatever your "Default" profile is.

With --font <PostScriptName>, also sets the font of your default profile
(keeping its current size), e.g. so Nerd Font icons from `eza --icons` render.

Usage: iterm_merge_prefs.py <repo-plist> [--font MesloLGSNF-Regular]
"""
import plistlib
import subprocess
import sys

DOMAIN = "com.googlecode.iterm2"

# Global (non-profile) settings worth carrying between machines.
KEYS = [
    # tmux -CC integration
    "ClosingTmuxTabKillsTmuxWindows",
    "ClosingTmuxTabKillsTmuxWindows_selection",
    "ClosingTmuxWindowKillsTmuxWindows",
    "ClosingTmuxWindowKillsTmuxWindows_selection",
    "TmuxSyncClipboard",
    "TmuxUnpauseAutomatically",
    # keys / mouse / trackpad (GlobalKeyMap includes Shift+Enter -> newline)
    "GlobalKeyMap",
    "PointerActions",
    "AlternateMouseScroll",
    "AllowClipboardAccess",
    # tabs / windows behavior
    "AddNewTabAtEndOfTabs",
    "TabStyleWithAutomaticOption",
    "ShowFullScreenTabBar",
    "OpenArrangementAtStartup",
    "OpenNoWindowsAtStartup",
    "PasteTabToStringTabStopSize",
    # touch-bar-less Esc feedback
    "HapticFeedbackForEsc",
    "SoundForEsc",
    "VisualIndicatorForEsc",
]


def set_default_profile_font(prefs: dict, font: str) -> bool:
    """Point the default profile's Normal Font at `font`, keeping its size."""
    guid = prefs.get("Default Bookmark Guid")
    for profile in prefs.get("New Bookmarks", []):
        if profile.get("Guid") != guid:
            continue
        current = profile.get("Normal Font", "Monaco 12")
        name, _, size = current.rpartition(" ")
        if not size.replace(".", "", 1).isdigit():
            size = "12"
        if name == font:
            return False
        profile["Normal Font"] = f"{font} {size}"
        print(f"    Default profile font: {current} -> {profile['Normal Font']}")
        return True
    return False


def main() -> int:
    args = sys.argv[1:]
    font = None
    if "--font" in args:
        i = args.index("--font")
        font = args[i + 1]
        del args[i : i + 2]

    with open(args[0], "rb") as f:
        repo = plistlib.load(f)

    exported = subprocess.run(
        ["defaults", "export", DOMAIN, "-"], capture_output=True, check=False
    ).stdout
    current = plistlib.loads(exported) if exported.strip() else {}

    changed = []
    for key in KEYS:
        if key not in repo:
            continue
        new = repo[key]
        old = current.get(key)
        # Dict-valued settings (key maps, pointer actions): add/override the
        # repo's entries but keep any of yours the repo doesn't define.
        if isinstance(new, dict) and isinstance(old, dict):
            new = {**old, **new}
        if old != new:
            current[key] = new
            changed.append(key)

    if font and set_default_profile_font(current, font):
        changed.append("Normal Font (default profile)")

    if not changed:
        print("    iTerm2 global prefs already up to date.")
        return 0

    subprocess.run(
        ["defaults", "import", DOMAIN, "-"],
        input=plistlib.dumps(current, fmt=plistlib.FMT_BINARY),
        check=True,
    )
    print(f"    Updated {len(changed)} iTerm2 prefs: {', '.join(changed)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
