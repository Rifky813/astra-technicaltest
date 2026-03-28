import os
import pandas as pd
import glob
from datetime import datetime
from sqlalchemy import create_engine

DB_URL = (
    f"mysql+pymysql://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@"
    f"{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)

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
    engine = create_engine(DB_URL)
    
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