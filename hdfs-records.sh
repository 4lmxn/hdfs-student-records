#!/usr/bin/env bash
# Load the student records into HDFS and query them.
# Assumes Hadoop is installed and HDFS daemons are running (jps shows NameNode + DataNode).
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

SRC="$(cd "$(dirname "$0")" && pwd)/students.csv"
HDFS_DIR="/user/$(whoami)/students"

echo "==> 1. Create the HDFS directory"
hdfs dfs -mkdir -p "$HDFS_DIR"

echo "==> 2. Copy the local records file into HDFS (overwrite if it exists)"
hdfs dfs -put -f "$SRC" "$HDFS_DIR/students.csv"

echo "==> 3. List the directory"
hdfs dfs -ls "$HDFS_DIR"

echo "==> 4. Print the full record list from HDFS"
hdfs dfs -cat "$HDFS_DIR/students.csv"

echo "==> 5. Row count (minus the header)"
echo "students = $(( $(hdfs dfs -cat "$HDFS_DIR/students.csv" | wc -l) - 1 ))"

echo "==> 6. Filter: CSE students only"
hdfs dfs -cat "$HDFS_DIR/students.csv" | awk -F, 'NR==1 || $3=="CSE"'

echo "==> 7. Filter: CGPA >= 8.5 (toppers)"
hdfs dfs -cat "$HDFS_DIR/students.csv" | awk -F, 'NR==1 || $5+0 >= 8.5'

echo "==> 8. Block / replication report for the file"
hdfs fsck "$HDFS_DIR/students.csv" -files -blocks || true

echo "Done. Web UI: http://localhost:9870  (Utilities -> Browse the file system)"
