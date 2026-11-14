#!/usr/bin/env bash
# Полная проверка контрольной точки. Результаты пишутся в папку docs/:
#   compose-ps.txt, crud-check.txt, persistence-check.txt, compose-logs.txt
# Запускать из корня проекта: bash scripts/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."
BASE="http://localhost:8080"
mkdir -p docs

wait_api() {
  echo "Жду запуск API..."
  for _ in $(seq 1 90); do
    if curl -s -o /dev/null -f "$BASE/products"; then echo "API готов"; return 0; fi
    sleep 2
  done
  echo "API не поднялся за 180 секунд" >&2
  docker compose logs --no-color api | tail -n 50 >&2
  exit 1
}

echo ">>> 1. docker compose up"
docker compose up -d --build
wait_api

echo ">>> 2. docker compose ps"
docker compose ps | tee docs/compose-ps.txt

echo ">>> 3. CRUD-проверка"
bash scripts/crud-check.sh "$BASE" | tee docs/crud-check.txt

echo ">>> 4. Перезапуск: docker compose down, затем up (volume db_data сохраняется)"
{
  echo "\$ docker compose down"
  docker compose down 2>&1
  echo
  echo "\$ docker compose up -d"
  docker compose up -d 2>&1
} | tee docs/persistence-check.txt
wait_api

{
  echo
  echo "\$ docker compose ps"
  docker compose ps
  echo
  echo "\$ curl $BASE/products   (после перезапуска)"
  curl -s "$BASE/products"
  echo
} | tee -a docs/persistence-check.txt

echo ">>> 5. docker compose logs"
docker compose logs --no-color > docs/compose-logs.txt
echo "Логи сохранены в docs/compose-logs.txt ($(wc -l < docs/compose-logs.txt) строк)"
echo "Готово. Файлы подтверждений лежат в docs/"
