#!/usr/bin/env python3
"""Quit the focused app like cmd-q (bound to super+q in cinnamon.sh).

Closes every window of the focused app (same WM_CLASS), as if each got alt+f4. Apps that only hide
to the tray (Discord, Slack, Spotify) are then sent SIGTERM. If a window is still open after the
wait (a "save changes?" prompt), the app is left alone so nothing is lost.

The pid comes from the X server (XRes), not _NET_WM_PID, which is a sandbox pid for flatpak apps.
"""
import os
import signal
import time

from Xlib import X, display, protocol
from Xlib.ext import res

d = display.Display()
root = d.screen().root
atom = d.intern_atom


def prop(win, name):
    p = win.get_full_property(atom(name), X.AnyPropertyType)
    return p.value if p else []


def wm_class(win):
    try:
        cls = win.get_wm_class()
    except Exception:
        return None
    return cls[1] if cls else None


def app_windows(cls):
    wins = (d.create_resource_object("window", w) for w in prop(root, "_NET_CLIENT_LIST"))
    return [w for w in wins if wm_class(w) == cls]


def owner_pid(win):
    spec = {"client": win.id, "mask": res.LocalClientPIDMask}
    for cid in d.res_query_client_ids([spec]).ids:
        if cid.spec.mask & res.LocalClientPIDMask and cid.value:
            return cid.value[0]
    return None


def close(win):
    ev = protocol.event.ClientMessage(
        window=win, client_type=atom("_NET_CLOSE_WINDOW"), data=(32, [X.CurrentTime, 2, 0, 0, 0])
    )
    root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)


active = prop(root, "_NET_ACTIVE_WINDOW")
if not active or not active[0]:
    raise SystemExit
win = d.create_resource_object("window", active[0])
# never the desktop (nemo draws the icons) or the panel
skip = {atom("_NET_WM_WINDOW_TYPE_DESKTOP"), atom("_NET_WM_WINDOW_TYPE_DOCK")}
if skip & set(prop(win, "_NET_WM_WINDOW_TYPE")):
    raise SystemExit
cls = wm_class(win)
if not cls:
    raise SystemExit

pids = {p for p in map(owner_pid, app_windows(cls)) if p}
for w in app_windows(cls):
    close(w)
d.flush()

for _ in range(20):
    time.sleep(0.1)
    if not app_windows(cls):
        break
else:
    raise SystemExit  # a window is still open, likely a save prompt: leave the app alone

time.sleep(0.5)  # let apps that exit on their own last window finish
for p in pids:
    try:
        os.kill(p, signal.SIGTERM)
    except ProcessLookupError:
        pass
