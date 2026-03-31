#!/usr/bin/env bash
set -euo pipefail

JENKINS_CONTAINER_NAME="${JENKINS_CONTAINER_NAME:-jenkins}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[jenkins][ERROR] docker command not found"
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$JENKINS_CONTAINER_NAME"; then
  echo "[jenkins] Stopping and removing: $JENKINS_CONTAINER_NAME"
  docker rm -f "$JENKINS_CONTAINER_NAME" >/dev/null
  echo "[jenkins] Removed"
else
  echo "[jenkins] Container not found: $JENKINS_CONTAINER_NAME"
fi
