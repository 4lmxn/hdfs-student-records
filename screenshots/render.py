#!/usr/bin/env python3
"""Render the captured terminal logs (screenshots/logs/*.log) into one PNG per lab activity.

Each log is the real stdout/stderr of a lab script. The cosmetic
`NativeCodeLoader` warning is dropped and long MapReduce INFO logs are
trimmed (marked in the image). Rendering uses headless Google Chrome.
"""
import html
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOGS = HERE / "logs"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WIDTH = 1280
COLS = 150          # chars per row at 13px Menlo inside WIDTH
LINE_PX = 19
CHROME_PX = 120     # title bar + padding

PROMPT = "almaaaann@mac HDFS %"


def read_log(name: str) -> list[str]:
    lines = (LOGS / f"{name}.log").read_text().splitlines()
    return [l for l in lines if "NativeCodeLoader" not in l]


def split_steps(lines: list[str]) -> tuple[str, list[tuple[str, list[str]]]]:
    """Split a script log on its '==> N. title' markers."""
    cmd, steps = lines[0][2:], []
    for line in lines[1:]:
        if line.startswith("==> "):
            steps.append((line[4:], []))
        elif steps:
            steps[-1][1].append(line)
    return cmd, steps


def trim_mapreduce(lines: list[str]) -> list[str]:
    """Keep the command, job start, final summary + result; mark the omitted INFO lines."""
    start = next(i for i, l in enumerate(lines) if "Running job" in l)
    summary = next(i for i, l in enumerate(lines) if "map 100% reduce 100%" in l)
    omitted = summary - start - 1
    return lines[: start + 1] + [f"... ({omitted} lines of per-task INFO log omitted) ..."] + lines[summary:]


def colour(line: str) -> str:
    esc = html.escape(line)
    if line.startswith("$ "):
        return f'<span class="p">{PROMPT}</span> <span class="c">{html.escape(line[2:])}</span>'
    if line.startswith("==> "):
        return f'<span class="h">{esc}</span>'
    if line.startswith("... ("):
        return f'<span class="o">{esc}</span>'
    if re.search(r"completed successfully|HEALTHY|succeeded|exit 0", line):
        return f'<span class="g">{esc}</span>'
    if re.search(r"\bERROR\b|safe mode", line):
        return f'<span class="r">{esc}</span>'
    return esc


def render(out_name: str, title: str, lines: list[str]) -> None:
    rows = sum(max(1, math.ceil(len(l.expandtabs()) / COLS)) for l in lines) + 1
    height = CHROME_PX + rows * LINE_PX
    body = "\n".join(colour(l) for l in lines) + f'\n<span class="p">{PROMPT}</span> <span class="cur"> </span>'
    page = f"""<!doctype html><meta charset="utf-8"><style>
body{{margin:0;background:#1b1d23;font:13px/{LINE_PX}px Menlo,monospace}}
.win{{margin:16px;border-radius:10px;background:#0f1115;box-shadow:0 8px 30px #0008;overflow:hidden}}
.bar{{height:30px;background:#2a2d35;display:flex;align-items:center;padding:0 12px;gap:8px;color:#9aa0aa;font:12px -apple-system,sans-serif}}
.d{{width:12px;height:12px;border-radius:50%}} .t{{flex:1;text-align:center;margin-right:60px}}
pre{{margin:0;padding:14px 16px;color:#d7dae0;white-space:pre-wrap;word-break:break-all;tab-size:8}}
.p{{color:#7fd88f}} .c{{color:#fff;font-weight:bold}} .h{{color:#61afef;font-weight:bold}}
.g{{color:#98c379}} .r{{color:#e06c75}} .o{{color:#7f848e;font-style:italic}} .cur{{background:#d7dae0}}
</style><div class="win"><div class="bar"><span class="d" style="background:#ff5f57"></span>
<span class="d" style="background:#febc2e"></span><span class="d" style="background:#28c840"></span>
<span class="t">{html.escape(title)} — zsh — ~/Projects/HDFS</span></div><pre>{body}</pre></div>"""
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(page)
    out = HERE / f"{out_name}.png"
    result = subprocess.run(
        [CHROME, "--headless=new", "--hide-scrollbars", "--force-device-scale-factor=2",
         f"--window-size={WIDTH},{height}", f"--screenshot={out}", f"file://{f.name}"],
        capture_output=True, text=True,
    )
    if result.returncode != 0 or not out.exists():
        sys.exit(f"chrome failed for {out_name}: {result.stderr}")
    print(f"wrote {out.name}")


def render_script(prefix: str, log: str, merge_empty: bool = True) -> None:
    """One image per '==>' step; a step with no output is merged into the next one."""
    cmd, steps = split_steps(read_log(log))
    pending: list[str] = []
    n = 0
    for title, out in steps:
        pending += [f"==> {title}"] + out
        if merge_empty and not [l for l in out if l.strip()]:
            continue
        n += 1
        render(f"{prefix}-step{n}", f"{cmd} — {title}", [f"$ {cmd}"] + pending)
        pending = []


def main() -> None:
    render("01-start-daemons", "Start HDFS daemons",
           read_log("00-jps-before") + read_log("01-daemons-start") + read_log("02-daemons-status"))
    render("02-safemode-wait", "Wait for NameNode to leave safe mode", read_log("02b-safemode-wait"))
    render_script("03-records", "03-hdfs-records")
    render("04-mapreduce-avg-cgpa", "MapReduce: average CGPA per branch",
           trim_mapreduce(read_log("04-mapreduce-avg-cgpa")))
    render("05-mapreduce-topper", "MapReduce: topper per branch",
           trim_mapreduce(read_log("05-mapreduce-topper")))
    render_script("06-admin", "06-hdfs-admin")


if __name__ == "__main__":
    main()
