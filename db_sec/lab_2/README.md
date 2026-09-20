# Лабораторная работа №2 — вариант 1

PostgreSQL 14+.

Порядок запуска:

```bash
docker compose -f lab_2/docker-compose.yml --env-file lab_2/.env up -d
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd lab_2
python3 lab2.py all
python3 lab2.py demo
```

Креды базы хранятся в `.env`; для примера есть `.env.example`.

`verify_access.sql` остаётся ручным SQL-сценарием проверки.

Ключевая реализованная идея: права выдаются только на представления, ограничения целостности и обновляемость реализованы триггерами, а действия пользователей логируются.
