"""Управляющая софтинка для лабораторной работы №1, вариант 7.

Запускает DDL/DML/права доступа в отдельной базе ``lab1_v7`` и показывает
демонстрационные запросы от имени разных ролей (сотрудник/руководитель).
"""

import argparse
import os
import sys
from dataclasses import dataclass
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent


@dataclass(frozen=True)
class PostgresConfig:
    """Подключение к PostgreSQL."""

    host: str
    port: str
    dbname: str
    user: str
    password: str

    def dsn(self) -> str:
        """Вернуть строку подключения для psycopg2."""
        return (
            f"host={self.host} port={self.port} dbname={self.dbname} "
            f"user={self.user} password={self.password}"
        )

    def with_user(self, user: str, password: str) -> "PostgresConfig":
        """Вернуть конфиг подключения под указанным пользователем."""
        return PostgresConfig(
            host=self.host,
            port=self.port,
            dbname=self.dbname,
            user=user,
            password=password,
        )


def load_credentials() -> PostgresConfig:
    """Загрузить параметры подключения из .env."""
    load_dotenv(BASE_DIR / ".env")
    return PostgresConfig(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
        dbname=os.getenv("POSTGRES_DB", "lab1_v7"),
        user=os.getenv("POSTGRES_USER", "postgres"),
        password=os.getenv("POSTGRES_PASSWORD", "postgres"),
    )


def ensure_database(config: PostgresConfig) -> None:
    """Создать отдельную базу данных lab1_v7, если её ещё нет.

    Подключение к server-базе ``postgres`` не изменяет никакие чужие БД,
    в том числе ``lab1``.
    """
    server = PostgresConfig(
        host=config.host,
        port=config.port,
        dbname="postgres",
        user=config.user,
        password=config.password,
    )
    with psycopg2.connect(server.dsn()) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s", (config.dbname,)
            )
            if cursor.fetchone() is not None:
                print(f'База данных "{config.dbname}" уже существует')
                return

    dbname = config.dbname.replace('"', '""')
    create_connection = psycopg2.connect(server.dsn())
    create_connection.autocommit = True
    try:
        with create_connection.cursor() as cursor:
            cursor.execute(f'CREATE DATABASE "{dbname}"')
        print(f'Создана база данных "{config.dbname}"')
    finally:
        create_connection.close()


def connection_info(config: PostgresConfig) -> str:
    """Вернуть короткую строку подключения для логов."""
    return f"{config.user}@{config.host}:{config.port}/{config.dbname}"


def run_sql_file(config: PostgresConfig, path: Path) -> None:
    """Выполнить SQL-файл как последовательность отдельных операторов.

    Учитывает долларовые кавычки ``$$`` (используются в plpgsql-блоках).
    """
    sql: str = path.read_text(encoding="utf-8")
    statements: list[str] = []
    buffer: list[str] = []
    inside_dollar_quote = False
    position = 0
    while position < len(sql):
        if sql.startswith("$$", position):
            inside_dollar_quote = not inside_dollar_quote
            buffer.append("$$")
            position += 2
            continue
        character = sql[position]
        if character == ";" and not inside_dollar_quote:
            statement = "".join(buffer).strip()
            if statement:
                statements.append(statement)
            buffer.clear()
        else:
            buffer.append(character)
        position += 1
    remaining = "".join(buffer).strip()
    if remaining:
        statements.append(remaining)

    with psycopg2.connect(config.dsn()) as connection:
        with connection.cursor() as cursor:
            for statement in statements:
                try:
                    cursor.execute(statement)
                except Exception as error:
                    print(f"ОШИБКА: {error}")
                    print(f"В выражении: {statement[:256]}")
                    connection.rollback()
                    raise
    print(f"Выполнено: {path.name}")


def run_demo_user(
    config: PostgresConfig,
    role: str,
    fio: str,
    statements: list[tuple[str, str]],
) -> None:
    """Выполнить набор запросов от имени роли и вывести результаты.

    Подключение выполняется системным пользователем ``postgres``, затем
    активируются роль ``role`` и сессионная переменная ``app.current_user``
    (имя сотрудника). RLS-политики сравнивают ФИО с этой переменной.
    """
    with psycopg2.connect(config.dsn()) as connection:
        with connection.cursor() as cursor:
            for statement, expected_note in statements:
                cursor.execute(f"SET ROLE {role}")
                cursor.execute(f"SET app.\"current_user\" = {fio!r}")
                print(f"\n-- {expected_note}")
                try:
                    cursor.execute(statement)
                    if cursor.description:
                        columns = [item[0] for item in cursor.description]
                        rows = cursor.fetchall()
                        print(" | ".join(columns))
                        for row in rows:
                            print(" | ".join(str(value) for value in row))
                    else:
                        print(f"OK, затронуто строк: {cursor.rowcount}")
                except Exception as error:
                    print(f"ОШИБКА: {error}")
                    connection.rollback()


def demo(config: PostgresConfig) -> None:
    """Продемонстрировать доступ сотрудника и руководителя проекта."""
    print(
        "Демонстрация лабораторной работы, "
        f"подключение: {connection_info(config)}"
    )

    employee_statements: list[tuple[str, str]] = [
        (
            "SELECT DISTINCT project_name FROM task ORDER BY project_name",
            "Сотрудник1 видит названия проектов, на которых работает (RLS)",
        ),
        (
            "SELECT project_name, task_name, executor_fio, workload_hours, "
            "plan_date, real_date, description FROM task ORDER BY project_name, task_name",
            "Сотрудник1 видит задачи без кода проекта и отметки руководителя",
        ),
        (
            "SELECT project_code, manager_approved FROM task",
            "Сотрудник1 пытается прочитать закрытые столбцы",
        ),
        (
            "SELECT count(project_name) FROM task "
            "WHERE project_name = 'Внедрение ERP-платформы'",
            "Сотрудник1 не видит задачи чужого проекта (count должен быть 0)",
        ),
        (
            "UPDATE task SET real_date = CURRENT_DATE "
            "WHERE project_name = 'Внедрение ERP-платформы' "
            "AND task_name = 'Миграция данных'",
            "Сотрудник1 пытается изменить чужую реальную дату",
        ),
        (
            "UPDATE task SET real_date = CURRENT_DATE "
            "WHERE project_name = 'Разработка CRM-системы' "
            "AND task_name = 'Настроить CI/CD'",
            "Сотрудник1 изменяет свою реальную дату",
        ),
    ]
    run_demo_user(config, "employee1", "Петров П. П.", employee_statements)

    manager_statements: list[tuple[str, str]] = [
        (
            "SELECT project_code, project_name, task_name, executor_fio, "
            "manager_approved FROM task ORDER BY project_code, task_name",
            "Руководитель1 видит все данные своего проекта",
        ),
        (
            "SELECT project_code, task_name FROM task "
            "WHERE project_code = 2 ORDER BY task_name",
            "Руководитель1 не видит чужой проект",
        ),
        (
            "UPDATE task SET manager_approved = true "
            "WHERE project_code = 1 AND task_name = 'Разработать модуль отчетов'",
            "Руководитель1 отмечает задачу своего проекта",
        ),
        (
            "SELECT count(project_name) FROM task WHERE project_name = 'Внедрение ERP-платформы'",
            "Руководитель1 не видит чужую задачу (count должен быть 0)",
        ),
        (
            "UPDATE task SET manager_approved = true "
            "WHERE project_code = 2 AND task_name = 'Миграция данных'",
            "Руководитель1 не может отметить чужой проект",
        ),
        (
            "SELECT DISTINCT project_name FROM task ORDER BY project_name",
            "Руководитель1 видит названия проектов, на которых работает (RLS)",
        ),
    ]
    run_demo_user(config, "manager1", "Смирнов С. С.", manager_statements)


def main() -> int:
    """Точка входа консольного сценария."""
    parser = argparse.ArgumentParser(
        description="Консольное управление лабораторной работой №1, вариант 7",
    )
    parser.add_argument(
        "mode",
        choices=["schema", "data", "access", "all", "demo", "sql"],
        help="schema, data, access, all, demo или sql",
    )
    parser.add_argument(
        "--file",
        help="SQL-файл для режима sql",
        dest="sql_file",
    )
    args = parser.parse_args()

    config: PostgresConfig = load_credentials()
    if args.mode == "sql":
        if not args.sql_file:
            parser.error("для режима sql требуется --file")
        run_sql_file(config, Path(args.sql_file).expanduser().resolve())
        return 0

    ensure_database(config)
    if args.mode in ("schema", "all"):
        run_sql_file(config, BASE_DIR / "schema.sql")
    if args.mode in ("data", "all"):
        run_sql_file(config, BASE_DIR / "data.sql")
    if args.mode in ("access", "all"):
        run_sql_file(config, BASE_DIR / "access.sql")
    if args.mode == "demo":
        demo(config)
    return 0


if __name__ == "__main__":
    sys.exit(main())
