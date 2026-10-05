#!/usr/bin/env python3
"""Stop Wine/Proton windows stealing focus when you switch back to their workspace.

Each Wine prefix (every Proton game is its own) thinks its window is the foreground one, so when
Muffin shows the workspace again the game asks to be activated, flagged as a pager request so
Muffin always obeys. Ghostty in front of workspace 1 came back behind two idle games.

The first window focused after a switch is the one Muffin (or focus-app, ulauncher) chose. For a
second after that, a Wine window taking focus gets it handed back. Anything else is left alone.
Started at login (scripts/keep-focus.desktop).
"""
import os
import time

from Xlib import X, display, protocol

GUARD = 1.0

d = display.Display()
root = d.screen().root
NET_ACTIVE_WINDOW = d.intern_atom("_NET_ACTIVE_WINDOW")
NET_CURRENT_DESKTOP = d.intern_atom("_NET_CURRENT_DESKTOP")
NET_CLIENT_LIST = d.intern_atom("_NET_CLIENT_LIST")
NET_WM_PID = d.intern_atom("_NET_WM_PID")


def prop(win, atom):
    try:
        p = win.get_full_property(atom, X.AnyPropertyType)
    except Exception:
        return []
    return list(p.value) if p else []


def is_wine(wid):
    pid = (prop(d.create_resource_object("window", wid), NET_WM_PID) or [0])[0]
    try:
        return "wine" in os.path.basename(os.readlink(f"/proc/{pid}/exe"))
    except OSError:
        return False


def activate(wid):
    ev = protocol.event.ClientMessage(
        window=d.create_resource_object("window", wid), client_type=NET_ACTIVE_WINDOW,
        data=(32, [2, X.CurrentTime, 0, 0, 0]))
    root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
    d.flush()


def main():
    root.change_attributes(event_mask=X.PropertyChangeMask)
    switched_at, chosen = 0.0, None
    while True:
        e = d.next_event()
        if e.type != X.PropertyNotify:
            continue
        if e.atom == NET_CURRENT_DESKTOP:
            switched_at, chosen = time.monotonic(), None
        elif e.atom == NET_ACTIVE_WINDOW and time.monotonic() - switched_at < GUARD:
            active = (prop(root, NET_ACTIVE_WINDOW) or [0])[0]
            if not active:
                continue
            if chosen is None:
                chosen = active
            elif active != chosen and is_wine(active) and chosen in prop(root, NET_CLIENT_LIST):
                activate(chosen)


main()
