#!/usr/bin/env bash
# HDFS feature tour on the student records: quota/usage, replication, append,
# fetch, checksum, snapshots, trash. Assumes NameNode + DataNode are up.
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="/user/$(whoami)/students"
FILE="$DIR/students.csv"

echo "==> 1. Cluster free space (df) and directory usage (du)"
hdfs dfs -df -h /
hdfs dfs -du -h "$DIR"

echo "==> 2. Ask for replication=2 on the file (1 DataNode => stays under-replicated, by design)"
hdfs dfs -setrep 2 "$FILE"   # no -w: with one DataNode the wait would never return
hdfs dfs -stat "replication=%r  size=%b  name=%n" "$FILE"

echo "==> 3. Append a late-admission record with appendToFile"
NEWROW="1KS21CS006,Tanvi Desai,CSE,6,8.90,Bangalore"
if hdfs dfs -cat "$FILE" | grep -q '^1KS21CS006,'; then
  echo "   (row already present — skipping the append so re-runs stay clean)"
else
  echo "$NEWROW" | hdfs dfs -appendToFile - "$FILE"
fi
echo "   tail of the file in HDFS:"
hdfs dfs -tail "$FILE"

echo "==> 4. Fetch the file back to local and diff against the repo copy"
hdfs dfs -get -f "$FILE" /tmp/students_from_hdfs.csv
diff <(sort "$HERE/students.csv") <(grep -v '^1KS21CS006' /tmp/students_from_hdfs.csv | sort) \
  && echo "   (identical apart from the appended row)"

echo "==> 5. Block checksum (what -distcp / -get use to verify integrity)"
hdfs dfs -checksum "$FILE"

echo "==> 6. Snapshots — capture, change, list the diff, restore"
hdfs dfsadmin -allowSnapshot "$DIR"
hdfs dfs -deleteSnapshot "$DIR" snap1 2>/dev/null || true
hdfs dfs -createSnapshot "$DIR" snap1
hdfs dfs -rm -f "$FILE"                     # goes to Trash, not gone
hdfs snapshotDiff "$DIR" snap1 .
echo "   restoring students.csv from the snapshot:"
hdfs dfs -cp "$DIR/.snapshot/snap1/students.csv" "$FILE"
hdfs dfs -stat "restored: size=%b" "$FILE"
hdfs dfs -deleteSnapshot "$DIR" snap1
hdfs dfsadmin -disallowSnapshot "$DIR"

echo "==> 7. Trash — the rm above parked a copy under .Trash; empty it"
hdfs dfs -ls -R "/user/$(whoami)/.Trash" 2>/dev/null | tail -3 || echo "   (trash empty)"
hdfs dfs -expunge

echo "Done."
