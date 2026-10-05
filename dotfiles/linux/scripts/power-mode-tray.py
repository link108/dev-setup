#!/usr/bin/env python3
"""Low power mode switch in the panel (the Cinnamon power applet's is hidden on a desktop).

The icon shows the active power profile and follows changes from anywhere (power-mode, gamemode,
powerprofilesctl). Left click toggles power-saver <-> balanced; right click picks any profile.
Both go through power-mode (scripts/power-mode.sh). Started at login by power-mode-tray.desktop.
"""
import os
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("XApp", "1.0")
from gi.repository import Gio, Gtk, XApp  # noqa: E402

POWER_MODE = os.path.expanduser("~/.local/bin/power-mode")
PROFILES = {
    "power-saver": ("Low power", "power-profile-power-saver-symbolic"),
    "balanced": ("Balanced", "power-profile-balanced-symbolic"),
    "performance": ("Performance", "power-profile-performance-symbolic"),
}

proxy = Gio.DBusProxy.new_for_bus_sync(
    Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, None,
    "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", None)
icon = XApp.StatusIcon(name="power-mode")
menu = Gtk.Menu()
items = {}


def run(*args):
    subprocess.Popen([POWER_MODE, *args])


def update(*_):
    active = proxy.get_cached_property("ActiveProfile").unpack()
    label, icon_name = PROFILES.get(active, (active, "power-profile-balanced-symbolic"))
    icon.set_icon_name(icon_name)
    icon.set_tooltip_text(f"Power mode: {label}\nClick to toggle low power mode")
    for name, item in items.items():
        item.handler_block_by_func(on_pick)
        item.set_active(name == active)
        item.handler_unblock_by_func(on_pick)


def on_pick(item, name):
    if item.get_active():
        run(name)


group = None
for name, (label, _icon) in PROFILES.items():
    item = Gtk.RadioMenuItem.new_with_label_from_widget(group, label)
    group = item
    item.connect("toggled", on_pick, name)
    menu.append(item)
    items[name] = item
menu.show_all()

icon.set_secondary_menu(menu)
icon.connect("activate", lambda *_: run())
proxy.connect("g-properties-changed", update)
update()
Gtk.main()
