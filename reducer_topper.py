#!/usr/bin/env python3
"""Input sorted by branch. Emit the single highest-CGPA student per branch."""
import sys

current = None
best_cgpa = -1.0
best_who = ""


def flush(branch):
    if branch is not None and best_who:
        print(f"{branch}\t{best_cgpa:.2f}\t{best_who}")


for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    branch, payload = line.split("\t")
    cgpa_str, name, usn = payload.split(";")
    cgpa = float(cgpa_str)
    if branch != current:
        flush(current)
        current = branch
        best_cgpa = -1.0
        best_who = ""
    if cgpa > best_cgpa:
        best_cgpa = cgpa
        best_who = f"{name} ({usn})"

flush(current)
