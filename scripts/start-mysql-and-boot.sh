#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_URL="${BASE_URL:-http://127.0.0.1:9080}"
RESET_DB="${RESET_DB:-0}"

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] '$1' not found"; exit 1; }; }

require_cmd docker

echo "[INFO] Ensure spring-data folders exist..."
mkdir -p "$ROOT_DIR/spring-data/env" "$ROOT_DIR/spring-data/logs"

# (선택) 로컬 빌드 jar 필요하면 사용
if [[ -x "$ROOT_DIR/gradlew" ]]; then
  echo "[INFO] Build jar (bootJar)..."
  ./gradlew bootJar -x test
fi

if [[ "$RESET_DB" == "1" ]]; then
  echo "[WARN] RESET_DB=1 -> docker compose down -v (DB will be wiped)"
  docker compose down -v --remove-orphans
else
  docker compose down --remove-orphans || true
fi

echo "[INFO] docker compose up..."
docker compose up -d --build --force-recreate

echo "[INFO] Waiting for MySQL healthy..."
for i in {1..60}; do
  status="$(docker inspect -f '{{.State.Health.Status}}' spring-starter-mysql 2>/dev/null || true)"
  if [[ "$status" == "healthy" ]]; then
    echo "[INFO] MySQL is healthy"
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "[ERROR] MySQL not healthy in time"
    docker logs --tail 200 spring-starter-mysql || true
    exit 1
  fi
  sleep 2
done

echo "[INFO] Apply init.sql (idempotent; fixes missing tables on reused volume)..."
docker exec -i spring-starter-mysql mysql -uroot -pstrong_pwd < "$ROOT_DIR/scripts/init.sql"

echo "[INFO] Waiting for API up: ${BASE_URL} ..."
for i in {1..60}; do
  if curl -fsS "${BASE_URL}/" >/dev/null 2>&1; then
    echo "[INFO] API is reachable"
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "[ERROR] API not reachable in time"
    docker logs --tail 200 linux-api-service-1 || true
    exit 1
  fi
  sleep 2
done

echo "[INFO] Run login tests..."
BASE_URL="$BASE_URL" "$ROOT_DIR/scripts/test-login.sh"
echo "[INFO] DONE"