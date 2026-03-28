# Dokumentasi Proyek ELT Data Warehouse

## Deskripsi
Proyek ini merupakan sistem pipeline data (Extract, Load, Transform) yang memproses data pelanggan dan transaksi penjualan. Sistem ini membaca data dari file CSV, menyimpannya ke database staging, melakukan pembersihan data, dan memuatnya ke dalam skema Data Warehouse serta Data Mart menggunakan MySQL. Seluruh proses berjalan di dalam environment Docker dan diotomatisasi menggunakan Cron.

## Arsitektur Database
Proses pengolahan data dibagi menjadi tiga skema database:
1. **Staging**: Tempat penyimpanan data mentah dari sumber eksternal. Tabel yang tersedia meliputi `customers_raw`, `sales_raw`, `after_sales_raw`, dan `customer_addresses`.
2. **Data Warehouse**: Penyimpanan data yang telah dibersihkan menggunakan pemodelan dimensional. Terdiri dari tabel dimensi (`dim_customer`) dan tabel fakta (`fact_sales`, `fact_after_sales`). Proses standardisasi format tanggal dan teks dilakukan sebelum data masuk ke skema ini. Memakai Surrogate Key sebagai Primary Key dari masing-masing tabel untuk menangani perubahan data seperti alamat pada customer (Slowly Changing Dimension).
3. **Data Mart**: Penyimpanan hasil agregasi data dari Data Warehouse untuk kebutuhan spesifik. Terdiri dari tabel `mart_sales_monthly` (rekapitulasi penjualan bulanan) dan `mart_customer_priority` (pengelompokan prioritas pelanggan berdasarkan riwayat servis).
<img width="1276" height="596" alt="Screenshot 2026-03-28 011409" src="https://github.com/user-attachments/assets/b4276ff7-21a4-4914-a625-3a60c29554f0" />

<img width="657" height="764" alt="Screenshot 2026-03-28 011310" src="https://github.com/user-attachments/assets/d379bb6c-f76d-462b-9a9f-956afdb11679" />

<img width="682" height="305" alt="image" src="https://github.com/user-attachments/assets/c9a417e3-c615-450b-96ce-481b4b2123b2" />

## Teknologi yang Digunakan
* Python 3.12 (Pandas, SQLAlchemy, PyMySQL, Python-dotenv, Cryptography)
* MySQL 8.0
* Docker dan Docker Compose
* Cron (Penjadwalan tugas)

## Alur Kerja Sistem
1. **Inisialisasi Database**: Saat container MySQL pertama kali berjalan, sistem mengeksekusi skrip SQL dari direktori `mysql-init/` untuk membuat struktur tabel, memuat data sampel awal, dan membuat Stored Procedure.
2. **Ekstraksi Data**: Skrip `extract.py` mencari file CSV dengan nama berformat `customer_address_*.csv` terbaru di folder `data_drops/`. Data tersebut dibaca dan dimasukkan ke tabel `customer_addresses` di database staging.
3. **Transformasi dan Pemuatan**: Skrip `main_elt.py` mengeksekusi dua Stored Procedure secara berurutan:
   * `sp_load_datawarehouse`: Memindahkan data dari tabel staging ke tabel Data Warehouse.
   * `sp_load_datamart`: Melakukan kalkulasi data dari Data Warehouse dan memperbarui isi tabel Data Mart.
4. **Otomatisasi**: Sistem Cron di dalam container Docker telah diatur untuk menjalankan skrip `main_elt.py` setiap hari pada pukul 01:00.

## Cara Menjalankan Proyek
1. Buat konfigurasi file `.env` di direktori utama dengan variabel berikut:
   ```env
   DB_HOST=mysql
   DB_USER=root
   DB_PASSWORD=root
   DB_NAME=staging
   DB_PORT=3306
2. Pastikan file sumber data berformat CSV berada di dalam folder  `data_drops/.`
3. Buka terminal pada direktori proyek dan jalankan perintah:
```bash
docker-compose up --build
```
4. Container akan aktif, menunggu layanan MySQL siap (sekitar 60 detik), dan langsung menjalankan proses ELT satu kali sebelum mengaktifkan jadwal cron.
5. Log proses penjadwalan akan tersimpan dan dapat diperiksa pada path `/var/log/cron.log` di dalam container etl.
6. Anda bisa connect ke server dengan MySQL Workbench memakai:
   - host: `localhost`
   - user: `root`
   - password: `root`
   - port: `3307`
