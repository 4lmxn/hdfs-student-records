#!/usr/bin/env python3
"""Input is sorted by branch. Emit: branch \t avg_cgpa \t count."""
import sys

current = None
total = 0.0
count = 0


def flush(branch):
    if branch is not None and count:
        print(f"{branch}\t{total / count:.2f}\t{count}")


for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    branch, cgpa = line.split("\t")
    cgpa = float(cgpa)
    if branch != current:
        flush(current)
        current = branch
        total = 0.0
        count = 0
    total += cgpa
    count += 1

flush(current)
