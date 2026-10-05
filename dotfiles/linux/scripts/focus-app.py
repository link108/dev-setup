#!/usr/bin/env python3
"""Switch to an app by key, like aerospace's alt-<letter> binds (bound in cinnamon.sh).

    focus-app <wm_class> <desktop-id>

Focuses the app's topmost window on the current workspace, else on another workspace (switching
to it). If one of its windows is already focused, goes to the next one, this workspace's first, so
pressing again cycles through them.
With no window open it launches the .desktop file, which also brings back an app hidden in the
tray. <wm_class> matches either half of WM_CLASS (instance or class), ignoring case.
"""
import subprocess
import sys
import time

from Xlib import X, display

d = display.Display()
root = d.screen().root


def prop(win, name):
    p = win.get_full_property(d.intern_atom(name), X.AnyPropertyType)
    return p.value if p else []


def wm_class(wid):
    try:
        return {c.lower() for c in d.create_resource_object("window", wid).get_wm_class() or ()}
    except Exception:
        return set()


def desktop(wid):
    return (list(prop(d.create_resource_object("window", wid), "_NET_WM_DESKTOP")) or [None])[0]


def main():
    want, desktop_id = sys.argv[1].lower(), sys.argv[2]
    # stacking order is bottom to top, but Muffin keeps it per workspace: raising a window on
    # another workspace doesn't move it up, so it can't tell which window was used last
    wins = [w for w in prop(root, "_NET_CLIENT_LIST_STACKING") if want in wm_class(w)]
    if not wins:
        subprocess.Popen(["gtk-launch", desktop_id], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return
    active = (list(prop(root, "_NET_ACTIVE_WINDOW")) or [0])[0]
    here = list(prop(root, "_NET_CURRENT_DESKTOP"))
    if active in wins:
        # this workspace's windows first, then the rest, each in the order they were opened
        opened = sorted((w for w in prop(root, "_NET_CLIENT_LIST") if w in wins),
                        key=lambda w: desktop(w) not in here)
        target = opened[(opened.index(active) + 1) % len(opened)]
    else:
        target = ([w for w in wins if desktop(w) in here] or wins)[-1]
    # activating a window on another workspace makes Muffin switch there but focus whatever it
    # would focus on that workspace (and does so just after the switch), so switch, let it settle,
    # then activate
    if desktop(target) not in here + [0xFFFFFFFF]:
        subprocess.run(["wmctrl", "-s", str(desktop(target))])
        for _ in range(20):
            time.sleep(0.02)
            if list(prop(root, "_NET_CURRENT_DESKTOP")) == [desktop(target)]:
                break
        time.sleep(0.1)
    subprocess.run(["wmctrl", "-ia", hex(target)])


main()
