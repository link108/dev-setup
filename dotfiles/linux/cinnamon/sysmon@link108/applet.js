// Panel text: CPU % and temp, memory %, GPU % and temp. Click opens gnome-system-monitor.
// Linked into ~/.local/share/cinnamon/applets and added to the panel by cinnamon.sh.
const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;

const INTERVAL_S = 2;
const decoder = new TextDecoder();

function read(path) {
    try {
        let [ok, bytes] = GLib.file_get_contents(path);
        return ok ? decoder.decode(bytes) : null;
    } catch (e) {
        return null;
    }
}

// hwmon numbering changes between boots, so look sensors up by driver name
function hwmon(name) {
    for (let i = 0; i < 32; i++) {
        let dir = `/sys/class/hwmon/hwmon${i}`;
        if ((read(`${dir}/name`) || "").trim() == name) return dir;
    }
    return null;
}

function pct(n) {
    return `${Math.round(n)}%`.padStart(4);
}

// green below warn, yellow from warn, red from hot
const GREEN = "#8ec07c", YELLOW = "#fabd2f", RED = "#fb4934";
const LIMITS = {
    usage: [50, 80],
    mem: [70, 90],
    cpuTemp: [75, 88], // ryzen runs up to 95°C by design
    gpuTemp: [70, 82], // nvidia starts throttling in the high 80s
};

function color(text, value, kind) {
    let [warn, hot] = LIMITS[kind];
    let c = value >= hot ? RED : value >= warn ? YELLOW : GREEN;
    return `<span foreground="${c}">${text}</span>`;
}

class SysMonApplet extends Applet.TextApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.actor.style = "font-family: monospace;";
        this.cpuDir = hwmon("k10temp") || hwmon("coretemp");
        this.hasNvidia = GLib.find_program_in_path("nvidia-smi") != null;
        this.prevCpu = null;
        this.gpu = null;
        this.gpuBusy = false;
        this.update();
    }

    cpuUsage() {
        let fields = (read("/proc/stat") || "").split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        let idle = fields[3] + fields[4];
        let total = fields.reduce((a, b) => a + b, 0);
        let prev = this.prevCpu;
        this.prevCpu = { idle, total };
        if (!prev || total == prev.total) return 0;
        return 100 * (1 - (idle - prev.idle) / (total - prev.total));
    }

    memory() {
        let m = {};
        for (let line of (read("/proc/meminfo") || "").split("\n")) {
            let [k, v] = line.split(/:\s+/);
            if (v) m[k] = parseInt(v);
        }
        let used = m.MemTotal - m.MemAvailable;
        return { pct: 100 * used / m.MemTotal, usedGb: used / 1048576, totalGb: m.MemTotal / 1048576 };
    }

    // k10temp: temp1 is Tctl (package), the rest are per-CCD
    cpuTemps() {
        if (!this.cpuDir) return [];
        let temps = [];
        for (let i = 1; i < 16; i++) {
            let t = read(`${this.cpuDir}/temp${i}_input`);
            if (t == null) continue;
            let label = (read(`${this.cpuDir}/temp${i}_label`) || `temp${i}`).trim();
            temps.push({ label, c: parseInt(t) / 1000 });
        }
        return temps;
    }

    pollGpu() {
        if (!this.hasNvidia || this.gpuBusy) return;
        this.gpuBusy = true;
        Util.spawnCommandLineAsyncIO(
            "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits",
            (stdout, stderr, code) => {
                this.gpuBusy = false;
                let v = stdout.trim().split(/,\s*/).map(Number);
                this.gpu = code == 0 && v.length == 4 ? { util: v[0], temp: v[1], memUsed: v[2], memTotal: v[3] } : null;
            });
    }

    update() {
        this.pollGpu();
        let cpu = this.cpuUsage();
        let mem = this.memory();
        let temps = this.cpuTemps();
        let parts = [`CPU ${color(pct(cpu), cpu, "usage")}` +
            (temps.length ? ` ${color(`${Math.round(temps[0].c)}°`, temps[0].c, "cpuTemp")}` : "")];
        parts.push(`MEM ${color(pct(mem.pct), mem.pct, "mem")}`);
        if (this.gpu)
            parts.push(`GPU ${color(pct(this.gpu.util), this.gpu.util, "usage")} ` +
                color(`${this.gpu.temp}°`, this.gpu.temp, "gpuTemp"));
        // values are colored with pango markup (see color()); set_applet_label would show it raw
        this._applet_label.clutter_text.set_markup(parts.join("  "));

        let tip = [`CPU ${cpu.toFixed(1)}%`];
        for (let t of temps) tip.push(`  ${t.label} ${t.c.toFixed(1)}°C`);
        tip.push(`Memory ${mem.usedGb.toFixed(1)} / ${mem.totalGb.toFixed(1)} GB`);
        if (this.gpu)
            tip.push(`GPU ${this.gpu.util}%  ${this.gpu.temp}°C`,
                `  VRAM ${(this.gpu.memUsed / 1024).toFixed(1)} / ${(this.gpu.memTotal / 1024).toFixed(1)} GB`);
        this.set_applet_tooltip(tip.join("\n"));

        this.timer = Mainloop.timeout_add_seconds(INTERVAL_S, () => {
            this.update();
            return false;
        });
    }

    on_applet_clicked() {
        Util.spawnCommandLineAsync("gnome-system-monitor -r");
    }

    on_applet_removed_from_panel() {
        if (this.timer) Mainloop.source_remove(this.timer);
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new SysMonApplet(metadata, orientation, panelHeight, instanceId);
}
