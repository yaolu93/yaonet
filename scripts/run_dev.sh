#!/usr/bin/env bash
set -euo pipefail

# Quick dev startup script for this Yaonet project
# Usage: ./scripts/run_dev.sh [--no-worker] [--force] [--map-to-local] [--port <port>] [--with-spring] [--spring-port <port>]

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="$BASEDIR/.venv"

mkdir -p "$BASEDIR/logs" "$BASEDIR/tmp"

echo "Base dir: $BASEDIR"

# ensure .env exists (copy from example if available)
if [ ! -f "$BASEDIR/.env" ]; then
  if [ -f "$BASEDIR/.env.example" ]; then
    echo ".env not found, copying .env.example -> .env"
    cp "$BASEDIR/.env.example" "$BASEDIR/.env"
  else
    echo "warning: .env not found and .env.example missing; proceed with defaults"
  fi
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

echo "Activating virtualenv..."
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

VENV_PY="$VENV_DIR/bin/python"

# Install requirements only when requirements.txt changed to save time on reruns
REQ_FILE="$BASEDIR/requirements.txt"
REQ_SHA_FILE="$VENV_DIR/.requirements_sha"
if [ -f "$REQ_FILE" ]; then
  REQ_SHA=$(sha256sum "$REQ_FILE" | awk '{print $1}')
else
  REQ_SHA=""
fi
PREV_SHA=""
if [ -f "$REQ_SHA_FILE" ]; then
  PREV_SHA=$(cat "$REQ_SHA_FILE")
fi

if [ "$REQ_SHA" != "$PREV_SHA" ]; then
  echo "Installing/updating Python requirements..."
  # Ensure pip exists inside the venv (some system Python builds require ensurepip)
  "$VENV_PY" -m ensurepip --upgrade >/dev/null 2>&1 || true
  "$VENV_PY" -m pip install --upgrade pip >/dev/null 2>&1 || true

  # Run pip install and capture output so we can detect PEP 668 errors and retry safely
  TMP_OUT=$(mktemp)
  if "$VENV_PY" -m pip install -r "$REQ_FILE" >"$TMP_OUT" 2>&1; then
    rm -f "$TMP_OUT"
  else
    # If pip failed due to PEP 668 (externally-managed-environment), retry once with
    # --break-system-packages and warn the user. This flag is necessary on some
    # Debian/Ubuntu-managed Python installs when modifying packages.
    if grep -qi "externally-managed-environment" "$TMP_OUT" >/dev/null 2>&1; then
      echo "pip install failed with PEP 668; retrying with --break-system-packages (one-time)"
      if "$VENV_PY" -m pip install --break-system-packages -r "$REQ_FILE" >>"$TMP_OUT" 2>&1; then
        rm -f "$TMP_OUT"
      else
        echo "Retry with --break-system-packages also failed. See $TMP_OUT for details." >&2
        cat "$TMP_OUT" >&2
        rm -f "$TMP_OUT"
        exit 1
      fi
    else
      echo "pip install failed. See $TMP_OUT for details." >&2
      cat "$TMP_OUT" >&2
      rm -f "$TMP_OUT"
      exit 1
    fi
  fi
  echo "$REQ_SHA" > "$REQ_SHA_FILE"
else
  echo "Requirements unchanged; skipping pip install"
fi

export FLASK_APP=yaonet.py
export FLASK_ENV=development
export FLASK_DEBUG=1

if ! "$VENV_PY" -m flask --version >/dev/null 2>&1; then
  echo "error: Flask module is not runnable from $VENV_PY" >&2
  echo "hint: check requirements installation in the virtualenv" >&2
  exit 127
fi

RQ_AVAILABLE=true
if ! "$VENV_PY" -m rq.cli --help >/dev/null 2>&1; then
  echo "warning: RQ module is not runnable from $VENV_PY; worker startup will be skipped"
  RQ_AVAILABLE=false
fi

if command -v redis-server >/dev/null 2>&1; then
  if ! pgrep -x redis-server >/dev/null 2>&1; then
    echo "Starting redis-server in background..."
    # start a minimal redis instance (use system redis if you prefer)
    redis-server --save "" --appendonly no &>/dev/null &
    sleep 0.5
  else
    echo "redis-server already running"
  fi
else
  echo "warning: redis-server not found on PATH; using REDIS_URL from environment if set"
fi

echo "Running DB migrations (flask db upgrade)..."
"$VENV_PY" -m flask db upgrade

echo "Compiling translations (flask translate compile)..."
"$VENV_PY" -m flask translate compile || true

# helper: find pids listening on a given TCP port
pids_on_port() {
  local port="$1"
  local pids=""
  if command -v lsof >/dev/null 2>&1; then
    pids=$(lsof -ti tcp:${port} || true)
  elif command -v ss >/dev/null 2>&1; then
    # ss output like: users:("/proc/1234/...")
    pids=$(ss -ltnp "sport = :${port}" 2>/dev/null | awk -F"pid=" '/pid=/ {print $2}' | awk -F"," '{print $1}' | tr '\n' ' ')
  else
    # fallback to netstat if available
    if command -v netstat >/dev/null 2>&1; then
      pids=$(netstat -ltnp 2>/dev/null | awk '/:'${port}' / {print $7}' | cut -d'/' -f1 | tr '\n' ' ')
    fi
  fi
  echo "$pids"
}

# parse args: support --no-worker and --force
START_WORKER=true
FORCE_KILL=false
BIND_HOST="127.0.0.1"
BIND_PORT="5000"
START_SPRING=false
SPRING_PORT="8080"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-worker)
      START_WORKER=false
      shift
      ;;
    --force)
      FORCE_KILL=true
      shift
      ;;
    --map-to-local)
      # Bind on all interfaces so host machine can access VM service via VM IP/port-forward.
      BIND_HOST="0.0.0.0"
      shift
      ;;
    --port)
      if [ "$#" -lt 2 ]; then
        echo "error: --port requires a value" >&2
        exit 1
      fi
      BIND_PORT="$2"
      shift 2
      ;;
    --with-spring)
      START_SPRING=true
      shift
      ;;
    --spring-port)
      if [ "$#" -lt 2 ]; then
        echo "error: --spring-port requires a value" >&2
        exit 1
      fi
      SPRING_PORT="$2"
      shift 2
      ;;
    *)
      # ignore unknown args
      shift
      ;;
  esac
done

if [ "$START_SPRING" = true ]; then
  SPRING_DIR="$BASEDIR/yaonet-products"
  SPRING_PID_FILE="$BASEDIR/tmp/spring_boot.pid"
  SPRING_LOG_FILE="$BASEDIR/logs/spring_boot.log"

  if [ ! -f "$SPRING_DIR/pom.xml" ]; then
    echo "error: Spring project not found at $SPRING_DIR" >&2
    exit 1
  fi
  if ! command -v mvn >/dev/null 2>&1; then
    echo "error: mvn is not installed or not on PATH; cannot start Spring Boot" >&2
    exit 127
  fi

  SPRING_PIDS=$(pids_on_port "$SPRING_PORT")
  if [ -n "$SPRING_PIDS" ]; then
    echo "Spring port $SPRING_PORT is in use by PID(s): $SPRING_PIDS"
    for pid in $SPRING_PIDS; do
      ps -p $pid -o pid,cmd --no-headers || true
    done
    if [ "$FORCE_KILL" = true ]; then
      echo "--force supplied, killing Spring port owner PID(s): $SPRING_PIDS"
      kill $SPRING_PIDS || true
      sleep 0.5
      for pid in $SPRING_PIDS; do
        if kill -0 $pid 2>/dev/null; then
          kill -9 $pid || true
        fi
      done
    else
      read -r -p "Kill these processes and free Spring port $SPRING_PORT? [y/N] " answer
      case "$answer" in
        [Yy]*)
          kill $SPRING_PIDS || true
          sleep 0.5
          for pid in $SPRING_PIDS; do
            if kill -0 $pid 2>/dev/null; then
              kill -9 $pid || true
            fi
          done
          ;;
        *)
          echo "Will not kill processes. Aborting Spring Boot start."
          exit 1
          ;;
      esac
    fi
  fi

  if [ -z "${PRODUCTS_SERVICE_URL:-}" ]; then
    export PRODUCTS_SERVICE_URL="http://127.0.0.1:$SPRING_PORT"
    echo "PRODUCTS_SERVICE_URL not set; defaulting to $PRODUCTS_SERVICE_URL"
  fi

  # Local dev defaults for Spring Boot product service.
  # Use embedded H2 unless caller explicitly provides PRODUCTS_DB_*.
  if [ -z "${PRODUCTS_DB_URL:-}" ]; then
    export PRODUCTS_DB_URL="jdbc:h2:file:$BASEDIR/tmp/yaonet-products-db;MODE=PostgreSQL"
    export PRODUCTS_DB_USER="sa"
    export PRODUCTS_DB_PASSWORD=""
    echo "PRODUCTS_DB_URL not set; defaulting to embedded H2 database"
  fi

  if [ -z "${FLASK_AUTH_BASE_URL:-}" ]; then
    export FLASK_AUTH_BASE_URL="http://127.0.0.1:$BIND_PORT/api"
    echo "FLASK_AUTH_BASE_URL not set; defaulting to $FLASK_AUTH_BASE_URL"
  fi

  echo "Starting Spring Boot in background on port $SPRING_PORT (logs/spring_boot.log)..."
  nohup mvn -f "$SPRING_DIR/pom.xml" spring-boot:run \
    -Dspring-boot.run.arguments="--server.port=$SPRING_PORT" > "$SPRING_LOG_FILE" 2>&1 &
  SPRING_PID=$!
  echo "$SPRING_PID" > "$SPRING_PID_FILE"

  # Fail fast if Spring exits immediately (common with DB/config errors).
  sleep 3
  if ! kill -0 "$SPRING_PID" 2>/dev/null; then
    echo "error: Spring Boot failed to start. Last log lines:" >&2
    tail -n 60 "$SPRING_LOG_FILE" >&2 || true
    exit 1
  fi
fi

if [ "$START_WORKER" = true ] && [ "$RQ_AVAILABLE" = true ]; then
  echo "Starting RQ worker in background (logs/rq_worker.log)..."
  nohup "$VENV_PY" -m rq.cli worker yaonet-tasks > "$BASEDIR/logs/rq_worker.log" 2>&1 &
  echo $! > "$BASEDIR/tmp/rq_worker.pid"
fi

# check port and optionally kill owner processes
PIDS=$(pids_on_port "$BIND_PORT")
if [ -n "$PIDS" ]; then
  echo "Port $BIND_PORT is in use by PID(s): $PIDS"
  for pid in $PIDS; do
    ps -p $pid -o pid,cmd --no-headers || true
  done
  if [ "$FORCE_KILL" = true ]; then
    echo "--force supplied, killing PIDs: $PIDS"
    kill $PIDS || true
    sleep 0.5
    # escalate if still running
    for pid in $PIDS; do
      if kill -0 $pid 2>/dev/null; then
        echo "PID $pid still alive, sending SIGKILL"
        kill -9 $pid || true
      fi
    done
  else
    read -r -p "Kill these processes and free port 5000? [y/N] " answer
    case "$answer" in
      [Yy]*)
        kill $PIDS || true
        sleep 0.5
        for pid in $PIDS; do
          if kill -0 $pid 2>/dev/null; then
            echo "PID $pid still alive, sending SIGKILL"
            kill -9 $pid || true
          fi
        done
        ;;
      *)
        echo "Will not kill processes. Aborting server start."
        exit 1
        ;;
    esac
  fi
fi

echo "Starting Flask development server (flask run)..."
if [ "$BIND_HOST" = "0.0.0.0" ]; then
  VM_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  echo "Mapping enabled: bound to all interfaces"
  echo "VM access URL: http://127.0.0.1:$BIND_PORT"
  if [ -n "${VM_IP:-}" ]; then
    echo "Host machine URL (bridge/host-only): http://$VM_IP:$BIND_PORT"
  fi
  echo "If VM uses NAT, add VM port forwarding: host $BIND_PORT -> guest $BIND_PORT"
else
  echo "Open http://127.0.0.1:$BIND_PORT"
fi

if [ "$START_SPRING" = true ]; then
  echo "Spring Boot API: http://127.0.0.1:$SPRING_PORT/api/products"
fi
"$VENV_PY" -m flask run --host="$BIND_HOST" --port="$BIND_PORT"
