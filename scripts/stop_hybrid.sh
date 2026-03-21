#!/usr/bin/env bash
set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$BASEDIR/tmp"

kill_if_running() {
  local pid="$1"
  local name="$2"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "[hybrid] stopping $name (PID: $pid)"
    kill "$pid" || true
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" || true
    fi
  else
    echo "[hybrid] $name not running"
  fi
}

FLASK_PID=""
SPRING_PID=""

if [ -f "$TMP_DIR/flask_hybrid.pid" ]; then
  FLASK_PID="$(cat "$TMP_DIR/flask_hybrid.pid")"
fi
if [ -f "$TMP_DIR/spring_hybrid.pid" ]; then
  SPRING_PID="$(cat "$TMP_DIR/spring_hybrid.pid")"
fi

kill_if_running "$FLASK_PID" "Flask"
kill_if_running "$SPRING_PID" "Spring Boot"

rm -f "$TMP_DIR/flask_hybrid.pid" "$TMP_DIR/spring_hybrid.pid"

echo "[hybrid] stopped"
