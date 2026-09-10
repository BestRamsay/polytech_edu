import argparse
from dataclasses import dataclass
import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent


@dataclass(frozen=True)
class PostgresConfig:
    host: str
    port: str
    dbname: str
    user: str
    password: str

    def dsn(self) -> str:
        return (
            f"host={self.host} port={self.port} dbname={self.dbname} "
            f"user={self.user} password={self.password}"
        )

    def with_user(self, user: str, password: str) -> "PostgresConfig":
        return PostgresConfig(
            host=self.host,
            port=self.port,
            dbname=self.dbname,
            user=user,
            password=password,
        )


def load_credentials() -> PostgresConfig:
    load_dotenv(BASE_DIR / ".env")
    return PostgresConfig(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
        dbname=os.getenv("POSTGRES_DB", "lab1"),
        user=os.getenv("POSTGRES_USER", "postgres"),
        password=os.getenv("POSTGRES_PASSWORD", "postgres"),
    )


def connection_info(config: PostgresConfig) -> str:
    return f"{config.user}@{config.host}:{config.port}/{config.dbname}"


def run_sql_file(config: PostgresConfig, path: Path):
    sql: str = path.read_text(encoding="utf-8")
    statements = list()
    buffer = list()
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
                    if cursor.description:
                        columns = [
                            item[0] for item in cursor.description
                        ]
                        print(" | ".join(columns))
                        for row in cursor.fetchall():
                            print(" | ".join(str(value) for value in row))
                    elif cursor.rowcount >= 0:
                        print(f"OK, затронуто строк: {cursor.rowcount}")
                except Exception as error:
                    print(f"ОШИБКА: {error}")
                    connection.rollback()
    print(f"Выполнено: {path.name}")


def run_demo_user(
    config: PostgresConfig,
    user: str,
    password: str,
    statements: list[tuple[str, str]],
) -> None:
    with psycopg2.connect(config.with_user(user, password).dsn()) as connection:
        with connection.cursor() as cursor:
            for statement, expected_note in statements:
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
    print(
        "Демонстрация лабораторной работы, "
        f"подключение: {connection_info(config)}"
    )
    doctor_statements: list[tuple[str, str]] = [
        (
            "SELECT prescription_number, patient_name, disease_code, "
            "doctor_name, validity_days FROM prescription "
            "ORDER BY prescription_number",
            "Врач1 видит все строки и персональные поля",
        ),
        (
            "UPDATE prescription SET validity_days = 100 "
            "WHERE prescription_number = 5",
            "Врач1 пытается изменить чужой рецепт",
        ),
        (
            "UPDATE prescription SET validity_days = 45 "
            "WHERE prescription_number = 1",
            "Врач1 изменяет свой рецепт",
        ),
    ]
    run_demo_user(config, "doctor1", "doctor1", doctor_statements)

    pharmacist_statements: list[tuple[str, str]] = [
        (
            "SELECT prescription_number, issue_date, validity_days, "
            "drug_name, drug_code, is_used, pharmacy_number "
            "FROM prescription ORDER BY prescription_number",
            "Провизор1 видит разрешённые столбцы",
        ),
        (
            "SELECT disease_code FROM prescription",
            "Провизор1 пытается прочитать закрытый столбец",
        ),
        (
            "UPDATE prescription SET pharmacy_number = 2 "
            "WHERE prescription_number = 1",
            "Провизор1 изменяет действующий рецепт",
        ),
        (
            "UPDATE prescription SET is_used = false "
            "WHERE prescription_number = 4",
            "Провизор1 пытается изменить использованный рецепт",
        ),
        (
            "UPDATE prescription SET is_used = false "
            "WHERE prescription_number = 7",
            "Провизор1 пытается изменить просроченный рецепт",
        ),
    ]
    run_demo_user(config, "pharmacist1", "pharmacist1",
                  pharmacist_statements)


def main():
    parser = argparse.ArgumentParser(
        description="Консольное управление лабораторной работой №1",
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

    if args.mode in ("schema", "all"):
        run_sql_file(config, BASE_DIR / "schema.sql")
    if args.mode in ("data", "all"):
        run_sql_file(config, BASE_DIR / "data.sql")
    if args.mode in ("access", "all"):
        run_sql_file(config, BASE_DIR / "access.sql")
    if args.mode == "demo":
        demo(config)


if __name__ == "__main__":
    main()
