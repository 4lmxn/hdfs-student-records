#!/usr/bin/env python3
"""Emit: branch \t cgpa;name;usn   (one line per student, header skipped)."""
import sys

for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("usn,"):
        continue
    fields = line.split(",")
    if len(fields) < 5:
        continue
    usn, name, branch = fields[0].strip(), fields[1].strip(), fields[2].strip()
    try:
        cgpa = float(fields[4])
    except ValueError:
        continue
    print(f"{branch}\t{cgpa};{name};{usn}")
