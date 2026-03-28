import os
import pandas as pd
import glob
from datetime import datetime
from sqlalchemy import create_engine

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "3306")),
    "user": os.environ.get("DB_USER"),
    "password": os.environ.get("DB_PASSWORD"),
    "database": os.environ.get("DB_NAME", "staging")
}

SOURCE_FOLDER = "./data_drops/"
FILE_PATTERN = "customer_address_*.csv"
TABLE_NAME = "customer_addresses"

def get_latest_file(folder, pattern):
    """Mencari file terbaru berdasarkan tanggal hari ini atau pola file."""
    files = glob.glob(os.path.join(folder, pattern))
    if not files:
        return None
    # Mengambil file terakhir berdasarkan urutan nama (karena format yyyymmdd)
    return max(files, key=os.path.normcase)

def ingest_csv_to_mysql():
    # Koneksi ke database
    conn_str = (
        f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@"
        f"{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )
    engine = create_engine(conn_str)
    
    # Cari file hari ini
    target_file = get_latest_file(SOURCE_FOLDER, FILE_PATTERN)
    
    if target_file:
        print(f"Memulai proses untuk file: {target_file}")
        
        try:
            df = pd.read_csv(target_file)
            df['created_at'] = pd.to_datetime(df['created_at'])
            
            # Load ke MySQL
            df.to_sql(TABLE_NAME, con=engine, if_exists='append', index=False)
            
            print(f"Ingest Berhasil: {len(df)} baris ke tabel {TABLE_NAME}.")
            
        except Exception as e:
            print(f"Error: {e}")
    else:
        print("Tidak ada file baru untuk diproses hari ini.")


if __name__ == "__main__":
    ingest_csv_to_mysql()