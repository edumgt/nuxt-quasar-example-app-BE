#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MYSQL_CONTAINER_NAME="${MYSQL_CONTAINER_NAME:-spring-starter-mysql}"
MYSQL_IMAGE="${MYSQL_IMAGE:-mysql:8.4}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-spring_starter}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-strong_pwd}"
INIT_SQL_FILE="${INIT_SQL_FILE:-$ROOT_DIR/scripts/init.sql}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker command not found"
  exit 1
fi

if [[ ! -x "$ROOT_DIR/gradlew" ]]; then
  echo "[ERROR] gradlew not found or not executable: $ROOT_DIR/gradlew"
  exit 1
fi

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -Fxq "$MYSQL_CONTAINER_NAME"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -Fxq "$MYSQL_CONTAINER_NAME"
}

if container_exists; then
  if container_running; then
    echo "[INFO] MySQL container '$MYSQL_CONTAINER_NAME' already running"
  else
    echo "[INFO] Starting existing MySQL container '$MYSQL_CONTAINER_NAME'"
    docker start "$MYSQL_CONTAINER_NAME" >/dev/null
  fi
else
  echo "[INFO] Creating MySQL container '$MYSQL_CONTAINER_NAME'"
  docker run -d \
    --name "$MYSQL_CONTAINER_NAME" \
    -p "$MYSQL_PORT":3306 \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MYSQL_DATABASE="$MYSQL_DB" \
    "$MYSQL_IMAGE" >/dev/null
fi

echo "[INFO] Waiting for MySQL readiness..."
for i in {1..60}; do
  if docker exec "$MYSQL_CONTAINER_NAME" mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --silent >/dev/null 2>&1; then
    echo "[INFO] MySQL is ready"
    break
  fi

  if [[ "$i" -eq 60 ]]; then
    echo "[ERROR] MySQL did not become ready in time"
    exit 1
  fi
  sleep 2
done

if [[ ! -f "$INIT_SQL_FILE" ]]; then
  echo "[ERROR] SQL file not found: $INIT_SQL_FILE"
  exit 1
fi

echo "[INFO] Applying SQL: $INIT_SQL_FILE"
docker exec -i "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$INIT_SQL_FILE"

echo "[INFO] Running Spring Boot with Gradle"
cd "$ROOT_DIR"
./gradlew bootRun
