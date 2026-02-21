#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:9080}"
API_CLIENT="${API_CLIENT:-default}"
PASSWORD="${PASSWORD:-1234}"

login() {
  local identity="$1"
  echo "[INFO] login test -> ${identity}"

  local response
  response="$(curl -sS -X POST "${BASE_URL}/api/auth/login" \
    -H "Content-Type: application/json" \
    -H "Accept-Apiclient: ${API_CLIENT}" \
    -H "User-Agent: shell-login-test" \
    -d "{\"user\":{\"emailOrUsername\":\"${identity}\",\"password\":\"${PASSWORD}\",\"loginFrom\":1}}")"

  if [[ "${response}" == *"authenticationToken"* ]]; then
    echo "[PASS] ${identity}"
  else
    echo "[FAIL] ${identity} -> ${response}"
    return 1
  fi
}

login "admin"
login "manager"
login "tester"

echo "[INFO] all login tests passed"