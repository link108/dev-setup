#!/usr/bin/env python3
"""Tailscale in the panel: the tailnet's devices, exit nodes and the connect switch.

Tailscale's own `tailscale systray` has no device list, so this replaces it. Clicking a device
copies its Tailscale IP; offline devices sit in their own submenu with when they were last seen.
The menu follows `tailscale status` every few seconds. Connecting and picking an exit node need
this user to be tailscale's operator (external/tailscale.sh). Started at login by
tailscale-tray.desktop.
"""
import json
import os
import subprocess
from datetime import datetime, timezone

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("XApp", "1.0")
from gi.repository import Gdk, GLib, Gtk, XApp  # noqa: E402

ICONS = os.path.join(os.path.dirname(os.path.realpath(__file__)), "tailscale-tray")
ADMIN = "https://login.tailscale.com/admin/machines"
POLL_SECONDS = 5

icon = XApp.StatusIcon(name="tailscale")
menu = Gtk.Menu()
clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
last = None


def tailscale(*args):
    subprocess.Popen(["tailscale", *args])
    GLib.timeout_add(1000, refresh)


def status():
    try:
        out = subprocess.run(["tailscale", "status", "--json"], capture_output=True, text=True, timeout=5)
        return json.loads(out.stdout)
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
        return None


def name(node):
    return (node.get("DNSName") or node["HostName"]).split(".")[0]


def ip(node):
    return (node.get("TailscaleIPs") or ["-"])[0]


def ago(stamp):
    try:
        seen = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return ""
    if seen.year < 2000:
        return ""
    secs = (datetime.now(timezone.utc) - seen).total_seconds()
    for unit, size in (("d", 86400), ("h", 3600), ("m", 60)):
        if secs >= size:
            return f"{int(secs // size)}{unit} ago"
    return "just now"


def row(left, right, on_click=None):
    """A menu item with the device name on the left and a dim detail on the right."""
    item = Gtk.MenuItem()
    box = Gtk.Box(spacing=24)
    box.pack_start(Gtk.Label(label=left, xalign=0), True, True, 0)
    detail = Gtk.Label(xalign=1)
    detail.set_markup(f"<span alpha='60%'>{GLib.markup_escape_text(right)}</span>")
    box.pack_end(detail, False, False, 0)
    item.add(box)
    if on_click:
        item.connect("activate", lambda *_: on_click())
    else:
        item.set_sensitive(False)
    return item


def label(text):
    item = Gtk.MenuItem(label=text)
    item.set_sensitive(False)
    return item


def button(text, on_click):
    item = Gtk.MenuItem(label=text)
    item.connect("activate", lambda *_: on_click())
    return item


def copy(text):
    clipboard.set_text(text, -1)
    clipboard.store()


def build(st):
    for child in menu.get_children():
        menu.remove(child)

    running = bool(st) and st.get("BackendState") == "Running"
    icon.set_icon_name(os.path.join(ICONS, "on.svg" if running else "off.svg"))
    if not st:
        icon.set_tooltip_text("Tailscale: not reachable")
        menu.append(label("tailscaled is not reachable"))
        menu.show_all()
        return

    peers = sorted(st.get("Peer", {}).values(), key=name)
    online = [p for p in peers if p.get("Online")]
    offline = [p for p in peers if not p.get("Online")]
    me = st["Self"]
    exit_node = next((p for p in peers if p.get("ExitNode")), None)

    tip = f"Tailscale: {'connected' if running else st.get('BackendState', '?').lower()}"
    if running:
        tip += f"\n{len(online)} of {len(peers)} devices online"
    if exit_node:
        tip += f"\nExit node: {name(exit_node)}"
    icon.set_tooltip_text(tip)

    menu.append(label("Connected" if running else st.get("BackendState", "Disconnected")))
    menu.append(button("Disconnect", lambda: tailscale("down")) if running
                else button("Connect", lambda: tailscale("up")))
    menu.append(Gtk.SeparatorMenuItem())
    menu.append(row(f"This device: {name(me)}", ip(me), lambda: copy(ip(me))))

    if running:
        menu.append(Gtk.SeparatorMenuItem())
        menu.append(label(f"Devices ({len(online)} online)  ·  click to copy IP"))
        for p in online:
            menu.append(row(name(p), ip(p), lambda p=p: copy(ip(p))))
        if offline:
            sub = Gtk.Menu()
            for p in offline:
                sub.append(row(name(p), ago(p.get("LastSeen")) or ip(p), lambda p=p: copy(ip(p))))
            item = Gtk.MenuItem(label=f"Offline ({len(offline)})")
            item.set_submenu(sub)
            menu.append(item)

        menu.append(Gtk.SeparatorMenuItem())
        sub = Gtk.Menu()
        options = [p for p in peers if p.get("ExitNodeOption")]
        group = Gtk.RadioMenuItem.new_with_label_from_widget(None, "None")
        group.set_active(exit_node is None)
        group.connect("toggled", lambda i: i.get_active() and tailscale("set", "--exit-node="))
        sub.append(group)
        for p in options:
            item = Gtk.RadioMenuItem.new_with_label_from_widget(group, name(p))
            item.set_active(p is exit_node)
            item.connect("toggled", lambda i, p=p: i.get_active() and tailscale("set", f"--exit-node={ip(p)}"))
            sub.append(item)
        if not options:
            sub.append(label("No devices offer an exit node"))
        item = Gtk.MenuItem(label=f"Exit node: {name(exit_node) if exit_node else 'none'}")
        item.set_submenu(sub)
        menu.append(item)

    menu.append(Gtk.SeparatorMenuItem())
    menu.append(button("Admin console", lambda: subprocess.Popen(["xdg-open", ADMIN])))
    menu.show_all()


def refresh():
    """Rebuild the menu when the tailnet changed; never under an open menu."""
    global last
    if menu.get_visible():
        return True
    st = status()
    key = json.dumps(st and {
        "state": st.get("BackendState"),
        "self": [name(st["Self"]), ip(st["Self"])],
        "peers": sorted((name(p), ip(p), p.get("Online"), p.get("ExitNode"), p.get("ExitNodeOption"),
                         ago(p.get("LastSeen")) if not p.get("Online") else "")
                        for p in st.get("Peer", {}).values()),
    }, sort_keys=True)
    if key != last:
        last = key
        build(st)
    return True


icon.set_primary_menu(menu)
icon.set_secondary_menu(menu)
refresh()
GLib.timeout_add_seconds(POLL_SECONDS, refresh)
Gtk.main()
