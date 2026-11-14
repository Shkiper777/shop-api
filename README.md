# Интернет-магазин

Контрольная точка: CRUD API на Java (Spring Boot), база PostgreSQL как отдельный сервис Docker Compose, данные хранятся в volume `db_data`.

## Связь с проектной темой

Тема проекта - интернет-магазин. Сущность CRUD - **Product (товар)**: это основа каталога. На схеме C4 (Container и Component) ей соответствуют `API Service`, `CatalogController`, `ProductRepository` и `PostgreSQL`. Redis из архитектурной схемы в этой контрольной точке не используется.

Поля товара: `id`, `name`, `description`, `price`, `stock`.

## Состав проекта

```
shop-api/
├── src/main/java/com/example/shop/   исходный код API
│   ├── ProductController.java       REST-эндпоинты
│   ├── ProductService.java          логика CRUD
│   ├── ProductRepository.java       доступ к PostgreSQL (Spring Data JPA)
│   ├── Product.java                 сущность (таблица products)
│   └── ProductRequest.java          тело запроса с валидацией
├── src/main/resources/application.yml   настройки, подключение берётся из переменных окружения
├── Dockerfile                       сборка и запуск API
├── docker-compose.yml               сервисы db и api
├── scripts/crud-check.sh            CRUD-проверка через curl
├── scripts/verify.sh                полная проверка, пишет результаты в docs/
└── docs/                            сюда verify.sh сохраняет подтверждения
```

## Сервисы docker-compose.yml

| Сервис | Образ | Назначение |
|---|---|---|
| `db` | `postgres:16` | PostgreSQL. База `app`, пользователь `postgres`, пароль `1234` |
| `api` | собирается из `Dockerfile` | Spring Boot API на порту 8080 |

- **Сеть:** оба сервиса в сети `shop-net`. API подключается к базе по имени сервиса: `DB_HOST=db` (Docker DNS разрешает `db` в адрес контейнера).
- **Переменные окружения API:** `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`. Адрес базы собирается в `application.yml`.
- **Volume:** `db_data` смонтирован в `/var/lib/postgresql/data`, поэтому данные переживают `docker compose down`.
- **depends_on:** `api` ждёт, пока `db` станет `healthy` (healthcheck через `pg_isready`).
- **Схема таблицы** создаётся автоматически при старте API (`ddl-auto: update`).

## Запуск

Нужен Docker Desktop или Docker Engine с Compose.

```bash
docker compose up --build
```

В другом терминале:

```bash
docker compose ps
docker compose logs
```

Остановка (данные сохраняются): `docker compose down`.
Полное удаление вместе с данными: `docker compose down -v`.

## Эндпоинты

| Метод | URL | Результат |
|---|---|---|
| GET | `/products` | список товаров, 200 |
| GET | `/products/{id}` | товар, 200 или 404 |
| POST | `/products` | создать товар, 201 |
| PUT | `/products/{id}` | изменить товар, 200 или 404 |
| DELETE | `/products/{id}` | удалить товар, 204 или 404 |

Неверные данные (пустое имя, отрицательная цена или остаток) дают 400.

## Примеры curl

```bash
# Создать
curl -X POST http://localhost:8080/products -H "Content-Type: application/json" \
  -d '{"name":"Mouse M1","description":"Wireless mouse","price":19.90,"stock":50}'

# Прочитать список и один товар
curl http://localhost:8080/products
curl http://localhost:8080/products/1

# Изменить
curl -X PUT http://localhost:8080/products/1 -H "Content-Type: application/json" \
  -d '{"name":"Mouse M1","description":"Wireless mouse, black","price":21.50,"stock":45}'

# Удалить
curl -X DELETE http://localhost:8080/products/1
```

В Windows PowerShell вместо `curl` используйте `curl.exe`, а JSON в `-d` берите в одинарные кавычки с экранированием двойных (`\"`), либо работайте через Git Bash или Postman.

## Проверка и подтверждения

Автоматически (нужен bash: Linux, macOS, Git Bash или WSL):

```bash
bash scripts/verify.sh
```

Скрипт поднимает систему, выполняет CRUD, делает `docker compose down` и `up`, проверяет, что данные на месте, и сохраняет вывод:

| Файл | Что подтверждает |
|---|---|
| `docs/compose-ps.txt` | сервисы `api` и `db` запущены |
| `docs/crud-check.txt` | Create, Read, Update, Delete, 404 и 400 |
| `docs/persistence-check.txt` | данные сохранились после перезапуска |
| `docs/compose-logs.txt` | вывод `docker compose logs` |

Вручную:

1. `docker compose up -d --build` и `docker compose ps`
2. `bash scripts/crud-check.sh` (создаёт товар «Keyboard K1», он останется в базе)
3. `docker compose down`, затем `docker compose up -d`
4. `curl http://localhost:8080/products` - «Keyboard K1» на месте
5. `docker compose logs`

