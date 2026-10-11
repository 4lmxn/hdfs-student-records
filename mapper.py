#!/usr/bin/env python3
"""Emit: branch \t cgpa   (one line per student, header skipped)."""
import sys

for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("usn,"):
        continue
    fields = line.split(",")
    if len(fields) < 5:
        continue
    branch = fields[2].strip()
    try:
        cgpa = float(fields[4])
    except ValueError:
        continue
    print(f"{branch}\t{cgpa}")
