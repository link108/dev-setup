#!/usr/bin/python3
"""Ulauncher, but picking an app that's already open switches to its window (like spotlight).

Ulauncher 5 always launches a new instance, so this wraps its entry point (/usr/bin/ulauncher) and
patches the launch action: if a window's WM_CLASS matches the app's .desktop file
(StartupWMClass, else the desktop id or the Exec binary), that window is raised, switching
workspace if needed. Apps hidden in the tray have no window, so they launch as usual, which
brings back the running instance anyway. Started at login by external/ulauncher.sh.
"""
import locale
import os
import re
import shlex
import subprocess

from ulauncher.api.shared.action import LaunchAppAction as launch_mod
from ulauncher.utils.desktop.reader import read_desktop_file

# launchers whose name says nothing about the app they start
WRAPPERS = {"flatpak", "env", "sh", "bash", "gtk-launch", "snap"}


def window_classes(app, filename):
    names = {app.get_string("StartupWMClass") or ""}
    if not any(names):
        names.add(os.path.splitext(os.path.basename(app.get_id() or filename))[0])
        exec_ = shlex.split(re.sub(r"%[a-zA-Z]", "", app.get_string("Exec") or ""))
        if exec_ and os.path.basename(exec_[0]) not in WRAPPERS:
            names.add(os.path.basename(exec_[0]))
    return {n.lower() for n in names if n}


def find_window(classes):
    # wmctrl -lx lists oldest first; take the last match so the most recent window wins
    out = subprocess.run(["wmctrl", "-lx"], capture_output=True, text=True).stdout
    match = None
    for line in out.splitlines():
        wid, _desk, wm_class = line.split(None, 3)[:3]
        if set(wm_class.lower().split(".", 1)) & classes:
            match = wid
    return match


original_run = launch_mod.LaunchAppAction.run


def run(self):
    app = read_desktop_file(self.filename)
    wid = app and find_window(window_classes(app, self.filename))
    if wid:
        subprocess.run(["wmctrl", "-ia", wid])
    else:
        original_run(self)


launch_mod.LaunchAppAction.run = run

locale.textdomain("ulauncher")
from ulauncher.main import main  # noqa: E402

main()
