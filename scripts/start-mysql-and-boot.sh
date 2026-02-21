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

# =========================================================
# ✅ NEW: preflight - free up MYSQL_PORT
#   1) stop docker containers publishing host port
#   2) kill WSL processes listening on the port
# =========================================================

stop_docker_containers_on_port() {
  local port="$1"

  # Containers that publish host port (e.g., 0.0.0.0:3306->3306/tcp)
  # "publish=3306" matches host-published port 3306
  local ids
  ids="$(docker ps --filter "publish=${port}" --format '{{.ID}} {{.Names}}' || true)"

  if [[ -z "${ids}" ]]; then
    return 0
  fi

  while read -r id name; do
    [[ -z "${id}" ]] && continue
    if [[ "${name}" == "${MYSQL_CONTAINER_NAME}" ]]; then
      continue
    fi
    echo "[WARN] Host port ${port} is published by container '${name}'. Stopping it..."
    docker stop "${id}" >/dev/null || true
  done <<< "${ids}"
}

kill_wsl_listeners_on_port() {
  local port="$1"

  # Find PIDs listening on TCP port (best effort)
  local pids=""

  if command -v lsof >/dev/null 2>&1; then
    pids="$(lsof -nP -iTCP:"${port}" -sTCP:LISTEN -t 2>/dev/null | sort -u || true)"
  elif command -v ss >/dev/null 2>&1; then
    # ss output example includes: users:(("mysqld",pid=1234,fd=...))
    pids="$(ss -ltnp 2>/dev/null \
      | awk -v p=":${port}" '$4 ~ p {print $NF}' \
      | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' \
      | sort -u || true)"
  fi

  if [[ -z "${pids}" ]]; then
    return 0
  fi

  echo "[WARN] WSL processes are listening on port ${port}: ${pids}"
  echo "[WARN] Sending TERM..."
  for pid in ${pids}; do
    kill -TERM "${pid}" 2>/dev/null || true
  done

  # Give them a moment to exit
  sleep 1

  # If still listening, force kill
  local still=""
  if command -v lsof >/dev/null 2>&1; then
    still="$(lsof -nP -iTCP:"${port}" -sTCP:LISTEN -t 2>/dev/null | sort -u || true)"
  elif command -v ss >/dev/null 2>&1; then
    still="$(ss -ltnp 2>/dev/null \
      | awk -v p=":${port}" '$4 ~ p {print $NF}' \
      | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' \
      | sort -u || true)"
  fi

  if [[ -n "${still}" ]]; then
    echo "[WARN] Still listening on ${port}: ${still}"
    echo "[WARN] Sending KILL..."
    for pid in ${still}; do
      kill -KILL "${pid}" 2>/dev/null || true
    done
  fi
}

echo "[INFO] Preflight: freeing host port ${MYSQL_PORT}..."
stop_docker_containers_on_port "${MYSQL_PORT}"
kill_wsl_listeners_on_port "${MYSQL_PORT}"

# =========================================================

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
./gradlew bootRun --args='--spring.profiles.active=dev'