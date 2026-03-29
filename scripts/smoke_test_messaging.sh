#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR"

COMPOSE="docker compose"
SMOKE_USER="${SMOKE_USER:-smoke_user}"
SMOKE_EMAIL="${SMOKE_EMAIL:-smoke_user@example.com}"
SMOKE_PASSWORD="${SMOKE_PASSWORD:-smoke_pass_123}"
WEB_BASE_URL="${WEB_BASE_URL:-http://localhost:8000}"
PRODUCTS_BASE_URL="${PRODUCTS_BASE_URL:-http://localhost:8080}"
PRODUCT_NAME="Smoke Product $(date +%Y%m%d%H%M%S)"

log() {
  printf '[smoke] %s\n' "$*"
}

fail() {
  printf '[smoke][FAIL] %s\n' "$*" >&2
  exit 1
}

wait_for_health() {
  local url="$1"
  local retries=30
  local i
  for i in $(seq 1 "$retries"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

wait_for_log_match() {
  local pattern="$1"
  local retries=20
  local i
  for i in $(seq 1 "$retries"); do
    if $COMPOSE logs --tail=300 products | grep -qE "$pattern"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

log "Starting services: db redis web rabbitmq kafka products"
$COMPOSE up -d db redis web rabbitmq kafka products >/dev/null

log "Waiting for Flask health endpoint"
wait_for_health "$WEB_BASE_URL/health" || fail "Web health endpoint not ready: $WEB_BASE_URL/health"

log "Bootstrapping Flask schema with db.create_all() and ensuring smoke user"
USER_ID="$($COMPOSE exec -T web python - <<'PY'
from app import create_app, db
from app.models import User

username = "smoke_user"
email = "smoke_user@example.com"
password = "smoke_pass_123"

app = create_app()
with app.app_context():
    db.create_all()
    user = User.query.filter_by(username=username).first()
    if not user:
        user = User(username=username, email=email)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
    print(user.id)
PY
)"

[[ "$USER_ID" =~ ^[0-9]+$ ]] || fail "Failed to obtain valid user id"
log "Using user id: $USER_ID"

log "Requesting token from Flask API"
TOKEN_JSON="$(curl -fsS -u "$SMOKE_USER:$SMOKE_PASSWORD" -X POST "$WEB_BASE_URL/api/tokens")"
TOKEN="$(printf '%s' "$TOKEN_JSON" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[[ -n "$TOKEN" ]] || fail "Token response did not include token. Response: $TOKEN_JSON"

log "Creating product via Spring products API"
CREATE_RESPONSE="$(curl -sS -w '\n%{http_code}' -X POST "$PRODUCTS_BASE_URL/api/products" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Yaonet-User-Id: $USER_ID" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$PRODUCT_NAME\",\"description\":\"e2e smoke\",\"price\":123.45,\"stock\":9,\"imageUrl\":\"https://example.com/p.png\"}")"

HTTP_CODE="$(printf '%s' "$CREATE_RESPONSE" | tail -n1)"
CREATE_BODY="$(printf '%s' "$CREATE_RESPONSE" | sed '$d')"
[[ "$HTTP_CODE" == "201" ]] || fail "Create product failed (HTTP $HTTP_CODE): $CREATE_BODY"

PRODUCT_ID="$(printf '%s' "$CREATE_BODY" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p')"
[[ "$PRODUCT_ID" =~ ^[0-9]+$ ]] || fail "Could not parse product id from response: $CREATE_BODY"
log "Created product id: $PRODUCT_ID"

log "Verifying outbox event published"
OUTBOX_ROW=""
for _ in $(seq 1 20); do
  OUTBOX_ROW="$($COMPOSE exec -T db psql -U postgres -d yaonet -t -A -c "select event_type||'|'||aggregate_id||'|'||coalesce(actor_id,'')||'|'||coalesce(published_at::text,'') from outbox_events where aggregate_id='${PRODUCT_ID}' order by id desc limit 1;")"
  if [[ -n "$OUTBOX_ROW" ]] && printf '%s' "$OUTBOX_ROW" | grep -q "product.created|${PRODUCT_ID}|${USER_ID}|"; then
    if printf '%s' "$OUTBOX_ROW" | awk -F'|' '{print $4}' | grep -q .; then
      break
    fi
  fi
  sleep 1
done

[[ -n "$OUTBOX_ROW" ]] || fail "No outbox row found for product id $PRODUCT_ID"
printf '%s' "$OUTBOX_ROW" | grep -q "product.created|${PRODUCT_ID}|${USER_ID}|" || fail "Outbox row content unexpected: $OUTBOX_ROW"
printf '%s' "$OUTBOX_ROW" | awk -F'|' '{print $4}' | grep -q . || fail "Outbox published_at is still empty: $OUTBOX_ROW"

log "Checking consumer logs for RabbitMQ and Kafka delivery"
wait_for_log_match "RabbitMQ consumed event type=product\.created aggregateId=${PRODUCT_ID}" || fail "RabbitMQ consumer log not found for product id $PRODUCT_ID"
wait_for_log_match "Kafka consumed event type=product\.created aggregateId=${PRODUCT_ID}" || fail "Kafka consumer log not found for product id $PRODUCT_ID"

log "Reading Kafka topic and asserting message payload contains product name"
KAFKA_DUMP="$($COMPOSE exec -T kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic yaonet.product.events --from-beginning --timeout-ms 12000 2>/dev/null || true)"
printf '%s' "$KAFKA_DUMP" | grep -q "$PRODUCT_NAME" || fail "Kafka topic does not contain product name '$PRODUCT_NAME'"

log "PASS: end-to-end smoke test succeeded"
log "Summary: product_id=$PRODUCT_ID user_id=$USER_ID"
