from pathlib import Path
import sqlite3

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"
DATABASE_PATH = PROCESSED_DATA_DIR / "fintech_funnel.db"
CREATE_TABLES_SQL_PATH = PROJECT_ROOT / "sql" / "01_create_tables.sql"


def read_csv_files():
    """
    Read raw CSV files into pandas DataFrames.
    """
    users = pd.read_csv(RAW_DATA_DIR / "users.csv")
    events = pd.read_csv(RAW_DATA_DIR / "events.csv")
    incentives = pd.read_csv(RAW_DATA_DIR / "incentives.csv")

    return users, events, incentives


def prepare_boolean_columns(users):
    """
    SQLite does not have a native Boolean type.

    This function converts True/False columns into 1/0 integers.
    """
    boolean_columns = ["kyc_required", "referred", "incentive_offered"]

    for column in boolean_columns:
        users[column] = users[column].astype(int)

    return users


def create_tables(connection):
    """
    Run the SQL script that creates the database tables.
    """
    with open(CREATE_TABLES_SQL_PATH, "r", encoding="utf-8") as file:
        create_tables_sql = file.read()

    connection.executescript(create_tables_sql)


def load_data(connection, users, events, incentives):
    """
    Load DataFrames into SQLite tables.
    """
    users.to_sql("users", connection, if_exists="append", index=False)
    events.to_sql("events", connection, if_exists="append", index=False)
    incentives.to_sql("incentives", connection, if_exists="append", index=False)


def validate_load(connection):
    """
    Print row counts after loading data.
    """
    tables = ["users", "events", "incentives"]

    for table in tables:
        query = f"SELECT COUNT(*) AS row_count FROM {table};"
        row_count = pd.read_sql_query(query, connection)["row_count"].iloc[0]
        print(f"{table}: {row_count:,} rows")

    print(f"\nSQLite database created at: {DATABASE_PATH}")


def main():
    PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)

    users, events, incentives = read_csv_files()
    users = prepare_boolean_columns(users)

    with sqlite3.connect(DATABASE_PATH) as connection:
        create_tables(connection)
        load_data(connection, users, events, incentives)
        validate_load(connection)


if __name__ == "__main__":
    main()
