# Лабораторная работа №1 — вариант 1

PostgreSQL 14+.

Порядок запуска:

```bash
docker compose -f lab_1/docker-compose.yml --env-file lab_1/.env up -d
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd lab_1
python3 lab1.py all
python3 lab1.py demo
```

Креды базы хранятся в `.env`; для примера есть `.env.example`.

`verify_access.sql` остаётся ручным SQL-сценарием проверки.

Ключевая реализованная идея: права на столбцы задаются `GRANT`, ограничения по строкам — RLS-политиками. Для врача недостаточное разделение по столбцам описано в `matrix.md`.
