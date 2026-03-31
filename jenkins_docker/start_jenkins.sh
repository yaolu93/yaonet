#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

JENKINS_CONTAINER_NAME="${JENKINS_CONTAINER_NAME:-jenkins}"
JENKINS_IMAGE_NAME="${JENKINS_IMAGE_NAME:-jenkins_with_docker}"
JENKINS_HOME_DIR="${JENKINS_HOME_DIR:-/mydata/jenkins_home}"
JENKINS_HTTP_PORT="${JENKINS_HTTP_PORT:-8180}"
JENKINS_AGENT_PORT="${JENKINS_AGENT_PORT:-50000}"

echo "[jenkins] Base dir: $BASE_DIR"
echo "[jenkins] Image: $JENKINS_IMAGE_NAME"
echo "[jenkins] Container: $JENKINS_CONTAINER_NAME"
echo "[jenkins] Home dir: $JENKINS_HOME_DIR"
echo "[jenkins] Ports: $JENKINS_HTTP_PORT (HTTP), $JENKINS_AGENT_PORT (Agent)"

if ! command -v docker >/dev/null 2>&1; then
  echo "[jenkins][ERROR] docker command not found"
  exit 1
fi

mkdir -p "$JENKINS_HOME_DIR"

echo "[jenkins] Building image..."
docker build -t "$JENKINS_IMAGE_NAME" "$BASE_DIR"

if docker ps -a --format '{{.Names}}' | grep -qx "$JENKINS_CONTAINER_NAME"; then
  echo "[jenkins] Existing container found, removing: $JENKINS_CONTAINER_NAME"
  docker rm -f "$JENKINS_CONTAINER_NAME" >/dev/null
fi

echo "[jenkins] Starting container..."
docker run -d \
  --name "$JENKINS_CONTAINER_NAME" \
  -u root \
  -p "$JENKINS_HTTP_PORT":8080 \
  -p "$JENKINS_AGENT_PORT":50000 \
  -v "$JENKINS_HOME_DIR":/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "$JENKINS_IMAGE_NAME" >/dev/null

echo "[jenkins] Started successfully"
echo "[jenkins] URL: http://localhost:$JENKINS_HTTP_PORT"
echo "[jenkins] Run ./get_admin_password.sh to fetch initial admin password"
