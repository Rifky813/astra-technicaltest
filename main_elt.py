import os
from sqlalchemy import create_engine, text
from extract import ingest_csv_to_mysql, DB_URL

PROCEDURES = [
    "sp_load_datawarehouse",
    "sp_load_datamart",
]


def call_stored_procedure(proc_name: str) -> None:
    """Memanggil Stored Procedures di-define di MySQL."""
    engine = create_engine(DB_URL)
    with engine.connect() as connection:
        print(f"Calling stored procedure: {proc_name}()")
        connection.execute(text(f"CALL {proc_name}()"))
        connection.commit()


if __name__ == "__main__":
    print("Memulai Proses ELT...")
    ingest_csv_to_mysql()

    for procedure in PROCEDURES:
        call_stored_procedure(procedure)

    print("Selesai. Data Mart berhasil di-update!")
