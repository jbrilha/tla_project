import argparse
import csv
import glob
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

JAVA = os.environ.get("JAVA") or shutil.which("java") or "java"
JAR = os.environ.get("TLA2TOOLS") or os.environ.get("CLASSPATH") or next(
    iter(sorted(glob.glob(os.path.expanduser("~/.vscode*/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar")))), "tla2tools.jar")


def parse_sweep(s):
    name, rng = s.split("=")
    lo, hi = rng.split("..")
    return name.strip(), range(int(lo), int(hi) + 1)


def set_constant(template, name, n):
    pattern = rf"^(\s*(?:CONSTANTS?\s+)?{re.escape(name)}\s*=\s*)(.*)$"
    m = re.search(pattern, template, flags=re.M)
    if not m:
        raise SystemExit(f"constant {name} not found in cfg")
    old = m.group(2).strip()
    if old.startswith("{"):
        first = re.match(r"\{\s*([A-Za-z_]*)", old).group(1) or "v"
        new = "{" + ", ".join(f"{first}{i}" for i in range(1, n + 1)) + "}"
    else:
        new = str(n)
    return template[:m.start(2)] + new + template[m.end(2):]


def run(spec, cfg_text, name, out, timeout):
    cfg = out / "cfg" / f"{name}.cfg"
    cfg.write_text(cfg_text)
    cmd = [JAVA, "-XX:+UseParallelGC", "-cp", JAR, "tlc2.TLC", "-workers", "auto",
           "-metadir", str((out / "states" / name).resolve()), "-config", str(cfg.resolve()), spec.name]
    start = time.time()
    try:
        text = subprocess.run(cmd, cwd=spec.parent, capture_output=True, text=True, timeout=timeout).stdout
        status = "error" if "Error:" in text else "ok"
    except subprocess.TimeoutExpired as e:
        text = e.stdout.decode() if isinstance(e.stdout, bytes) else e.stdout or ""
        status = "timeout"
    secs = round(time.time() - start, 1)
    shutil.rmtree(out / "states" / name, ignore_errors=True)
    found = re.findall(r"([\d,]+) states generated(?: \([^)]*\))?, ([\d,]+) distinct states found", text)
    depth = re.search(r"depth of the complete state graph search is (\d+)", text)
    gen, distinct = found[-1] if found else ("", "")
    return {"generated": gen.replace(",", ""), "distinct": distinct.replace(",", ""),
            "depth": depth.group(1) if depth else "", "seconds": secs, "status": status}


def main():
    ap = argparse.ArgumentParser(description="Run TLC over a range of values for one constant.")
    ap.add_argument("--spec", required=True, type=Path, help="the .tla module")
    ap.add_argument("--cfg", required=True, action="append", type=Path, help="template .cfg, repeatable")
    ap.add_argument("--sweep", required=True, action="append", type=parse_sweep,
                    help="NAME=LO..HI, repeatable. A set constant becomes a set of LO..HI model values.")
    ap.add_argument("--timeout", type=int, default=600, help="seconds per model (default 600)")
    ap.add_argument("--out", type=Path, default=Path("results"), help="output directory (default ./results)")
    args = ap.parse_args()

    missing = [str(c) for c in [args.spec, *args.cfg] if not c.is_file()]
    if missing:
        raise SystemExit(f"not found: {', '.join(missing)}")
    templates = [(cfg, cfg.read_text()) for cfg in args.cfg]

    (args.out / "cfg").mkdir(parents=True, exist_ok=True)
    rows = []
    for cfg, template in templates:
        for const, rng in args.sweep:
            for n in rng:
                name = f"{cfg.stem}_{const}{n}"
                row = {"cfg": cfg.name, "constant": const, "value": n,
                       **run(args.spec.resolve(), set_constant(template, const, n), name, args.out, args.timeout)}
                rows.append(row)
                print(row, flush=True)
                if row["status"] == "timeout":
                    break

    fields = list(rows[0])
    with open(args.out / "scale.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fields)
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
