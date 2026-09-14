# Лабораторная работа №1 — вариант 7

PostgreSQL 16+ (тот же контейнер `db_sec_lab1_postgres`, что и вариант 1,
но отдельная база данных `lab1_v7`).

Порядок запуска:

```bash
docker compose -f lab_1/docker-compose.yml --env-file lab_1/.env up -d
python3 -m venv .venv
source .venv/bin/activate
pip install -r lab_1_v7/requirements.txt
cd lab_1_v7
python3 lab1.py all
python3 lab1.py demo
```

Когда контейнер уже запущен (вариант 1), повторный `up -d` ничего не
ломает — используется та же БД-служба, а для варианта 7 создаётся
отдельная база `lab1_v7`. База `lab1` не изменяется.

Ключевая реализованная идея: права на столбцы задаются `GRANT`,
ограничения по строкам — RLS-политиками. «Кто я» для политик —
сессионная переменная `app.current_user` (ФИО сотрудника). Роли
сотрудника и руководителя — отдельные.
