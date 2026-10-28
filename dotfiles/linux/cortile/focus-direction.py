#!/usr/bin/env python3
"""Focus the nearest window in a direction (left|down|up|right) on the current workspace.

Cortile only cycles focus next/previous, so this fills in aerospace-style hjkl focus.
With --swap the focused window trades tiles with that neighbour instead (aerospace's move).
Bound to alt+h/j/k/l and alt+shift+h/j/k/l by cinnamon.sh. Needs wmctrl, xprop, xwininfo and busctl.
"""
import subprocess
import sys
import time


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def prop(win, name):
    return run("xprop", "-id", win, name)


def current_desktop():
    for line in run("wmctrl", "-d").splitlines():
        parts = line.split()
        if parts[1] == "*":
            return parts[0]
    return None


def active_window():
    out = run("xprop", "-root", "_NET_ACTIVE_WINDOW").strip()
    return int(out.split()[-1], 16) if "0x" in out else None


def geometry(wid):
    """Visible rect: wmctrl -G is off under Muffin, and GTK windows draw their own shadows."""
    info = {}
    for line in run("xwininfo", "-id", wid).splitlines():
        key, _, val = line.strip().partition(":")
        info[key] = val.strip()
    x, y = int(info["Absolute upper-left X"]), int(info["Absolute upper-left Y"])
    w, h = int(info["Width"]), int(info["Height"])
    extents = prop(wid, "_GTK_FRAME_EXTENTS")
    if "=" in extents:
        left, right, top, bottom = (int(v) for v in extents.split("=")[1].split(","))
        x, y, w, h = x + left, y + top, w - left - right, h - top - bottom
    return x, y, w, h


def windows(desktop):
    for line in run("wmctrl", "-l").splitlines():
        wid, desk = line.split()[:2]
        if desk != desktop:
            continue
        wtype = prop(wid, "_NET_WM_WINDOW_TYPE")
        # no type at all (Blender) means normal, per EWMH
        if "NORMAL" not in wtype and "DIALOG" not in wtype and "not found" not in wtype:
            continue
        if "HIDDEN" in prop(wid, "_NET_WM_STATE"):
            continue
        yield (int(wid, 16), *geometry(wid))


# windows must share more than this many px across the other axis to count as lined up
TOLERANCE = 20


def overlap(a0, a1, b0, b1):
    """Length of the shared span of two ranges (negative = gap between them)."""
    return min(a1, b1) - max(a0, b0)


def cortile(action):
    name, path = "com.github.leukipp.cortile", "/com/github/leukipp/cortile"
    subprocess.run(["busctl", "--user", "call", name, path, name, "ActionExecute", "sii",
                    action, current_desktop(), "0"], capture_output=True)


def wait(check, timeout=0.5):
    end = time.monotonic() + timeout
    while not check() and time.monotonic() < end:
        time.sleep(0.02)


def make_master(wid):
    """Focus a window and have cortile swap it with the first master (its only swap action)."""
    before = geometry(hex(wid))
    if active_window() != wid:
        subprocess.run(["wmctrl", "-ia", hex(wid)])
        wait(lambda: active_window() == wid)
        time.sleep(0.05)  # let cortile see the focus change too
    cortile("master_make")
    wait(lambda: geometry(hex(wid)) != before)


def swap(a, b, wins):
    """Swap tiles a and b. Cortile's dbus WindowToPosition is meant to do this (it fakes a drag)
    but never finds the drop target under Muffin, so build it from master swaps instead."""
    _, ax, ay, aw, ah = next(win for win in wins if win[0] == a)
    make_master(a)

    def in_old_tile(wid):
        x, y, w, h = geometry(hex(wid))
        return ax <= x + w // 2 <= ax + aw and ay <= y + h // 2 <= ay + ah

    # whatever took a's old tile was the master; if nothing moved, a already was
    master = next((win[0] for win in wins if win[0] != a and in_old_tile(win[0])), a)
    if master != b:
        make_master(b)
        if master != a:
            make_master(master)
    subprocess.run(["wmctrl", "-ia", hex(a)])


def main():
    args = sys.argv[1:]
    swapping = "--swap" in args
    args = [a for a in args if a != "--swap"]
    direction = args[0] if args else ""
    if direction not in ("left", "down", "up", "right"):
        sys.exit("usage: focus-direction.py [--swap] left|down|up|right")

    wins = list(windows(current_desktop()))
    active = active_window()
    cur = next((win for win in wins if win[0] == active), None)
    if cur is None:
        return

    _, x, y, w, h = cur
    best, best_cost = None, None
    for wid, ox, oy, ow, oh in wins:
        if wid == active:
            continue
        # ahead: how far their centre is past ours; dist: gap between facing edges;
        # shared: how much they line up across the other axis (must line up, then closest wins)
        if direction == "left":
            ahead, dist = x * 2 + w - ox * 2 - ow, x - (ox + ow)
            shared = overlap(y, y + h, oy, oy + oh)
        elif direction == "right":
            ahead, dist = ox * 2 + ow - x * 2 - w, ox - (x + w)
            shared = overlap(y, y + h, oy, oy + oh)
        elif direction == "up":
            ahead, dist = y * 2 + h - oy * 2 - oh, y - (oy + oh)
            shared = overlap(x, x + w, ox, ox + ow)
        else:
            ahead, dist = oy * 2 + oh - y * 2 - h, oy - (y + h)
            shared = overlap(x, x + w, ox, ox + ow)
        if ahead <= 0 or shared <= TOLERANCE:
            continue
        cost = max(dist, 0)
        if best_cost is None or cost < best_cost:
            best, best_cost = wid, cost

    if best is None:
        return
    if swapping:
        swap(active, best, wins)
    else:
        subprocess.run(["wmctrl", "-ia", hex(best)])


if __name__ == "__main__":
    main()
