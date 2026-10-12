#!/usr/bin/env bash
# The six lab tasks, one step each: create dir, upload, list+display, sort/filter,
# download, delete. Every command is echoed before it runs so the output reads like a session.
# Assumes NameNode + DataNode are up and out of safe mode.
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

cd "$(dirname "$0")"
DIR="/user/$(whoami)/student_info"
FILE="$DIR/students.csv"

run() { echo "\$ $*"; eval "$@"; echo; }

echo "==> 1. Create a directory"
run hdfs dfs -mkdir -p "$DIR"
run hdfs dfs -ls "/user/$(whoami)"

echo "==> 2. Upload students info"
run hdfs dfs -put -f students.csv "$DIR/"
run hdfs dfs -ls "$DIR"

echo "==> 3. List and display its contents"
run hdfs dfs -ls -h "$DIR"
run hdfs dfs -cat "$FILE"

echo "==> 4. Perform basic sorting/filtering"
run "hdfs dfs -cat $FILE | tail -n +2 | sort -t, -k5 -nr        # sort by CGPA, highest first"
run "hdfs dfs -cat $FILE | awk -F, 'NR==1 || \$3==\"CSE\"'      # filter: CSE branch only"
run "hdfs dfs -cat $FILE | awk -F, 'NR==1 || \$5+0 >= 8.5'      # filter: CGPA >= 8.5"

echo "==> 5. Download the file"
mkdir -p downloaded && rm -f downloaded/students.csv
run hdfs dfs -get "$FILE" downloaded/students.csv
run ls -l downloaded/students.csv
run "diff students.csv downloaded/students.csv && echo 'downloaded copy is identical to the original'"

echo "==> 6. Delete the file and directory"
run hdfs dfs -rm -skipTrash "$FILE"
run hdfs dfs -ls "$DIR"
run hdfs dfs -rm -r -skipTrash "$DIR"
run "hdfs dfs -ls $DIR || true"
