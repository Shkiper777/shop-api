#!/usr/bin/env bash
# Проверка CRUD: создаёт, читает, меняет и удаляет временный товар.
# Дополнительно создаёт товар "Keyboard K1", который остаётся в базе для проверки сохранения данных.
# Использование: scripts/crud-check.sh [BASE_URL]
set -u
BASE="${1:-http://localhost:8080}"
JSON='Content-Type: application/json'

run() {
  echo
  echo "\$ curl $*"
  curl -s -w '\nHTTP %{http_code}\n' "$@"
}

echo "=== CREATE ==="
out=$(curl -s -w '\nHTTP %{http_code}' -X POST "$BASE/products" -H "$JSON" \
  -d '{"name":"Mouse M1","description":"Wireless mouse","price":19.90,"stock":50}')
echo "\$ curl -X POST $BASE/products -H '$JSON' -d '{\"name\":\"Mouse M1\",...}'"
echo "$out"
ID=$(echo "$out" | sed -n 's/.*"id": *\([0-9][0-9]*\).*/\1/p' | head -n1)
if [ -z "$ID" ]; then echo "Не удалось получить id созданного товара" >&2; exit 1; fi

echo; echo "=== READ (list) ==="
run "$BASE/products"

echo; echo "=== READ (one) ==="
run "$BASE/products/$ID"

echo; echo "=== UPDATE ==="
run -X PUT "$BASE/products/$ID" -H "$JSON" \
  -d '{"name":"Mouse M1","description":"Wireless mouse, black","price":21.50,"stock":45}'

echo; echo "=== DELETE ==="
run -X DELETE "$BASE/products/$ID"

echo; echo "=== READ after delete (ожидается 404) ==="
run "$BASE/products/$ID"

echo; echo "=== Валидация (ожидается 400) ==="
run -X POST "$BASE/products" -H "$JSON" -d '{"name":"","price":-1,"stock":-5}'

echo; echo "=== CREATE товара, который останется в базе ==="
run -X POST "$BASE/products" -H "$JSON" \
  -d '{"name":"Keyboard K1","description":"Mechanical keyboard","price":79.00,"stock":20}'
