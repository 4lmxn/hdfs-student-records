#!/usr/bin/env bash
# Start / stop the single-node HDFS daemons (no SSH needed).
#   ./hadoop-daemons.sh start | stop | status
set -euo pipefail
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

case "${1:-status}" in
  start)
    hdfs --daemon start namenode
    hdfs --daemon start datanode
    sleep 4 && jps | grep -E 'NameNode|DataNode'
    echo "Web UI: http://localhost:9870"
    ;;
  stop)
    hdfs --daemon stop datanode
    hdfs --daemon stop namenode
    ;;
  status)
    jps | grep -E 'NameNode|DataNode' || echo "HDFS not running"
    ;;
  *) echo "usage: $0 start|stop|status"; exit 1 ;;
esac
