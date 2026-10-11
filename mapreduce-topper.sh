#!/usr/bin/env bash
# Hadoop Streaming job: highest-CGPA student per branch from the HDFS student records.
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

HERE="$(cd "$(dirname "$0")" && pwd)"
STREAMING_JAR=$(ls "$(brew --prefix hadoop)"/libexec/share/hadoop/tools/lib/hadoop-streaming-*.jar | head -1)
IN="/user/$(whoami)/students/students.csv"
OUT="/user/$(whoami)/students/topper_out"

hdfs dfs -rm -r -f "$OUT"

hadoop jar "$STREAMING_JAR" \
  -files "$HERE/mapper_topper.py,$HERE/reducer_topper.py" \
  -mapper mapper_topper.py \
  -reducer reducer_topper.py \
  -input "$IN" \
  -output "$OUT"

echo
echo "=== branch    top_cgpa   student ==="
hdfs dfs -cat "$OUT/part-*"
