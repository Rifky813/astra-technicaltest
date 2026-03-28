FROM python:3.12-slim

# Install cron and MySQL client tools
RUN apt-get update && apt-get install -y cron default-mysql-client && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install library
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Setup Cron
# 'printenv > /etc/environment' agar cron bisa baca .env
RUN echo "0 1 * * * . /etc/environment; /usr/local/bin/python /app/main_elt.py >> /var/log/cron.log 2>&1" > /etc/cron.d/etl-cron
RUN chmod 0644 /etc/cron.d/etl-cron && crontab /etc/cron.d/etl-cron

# Buat file log
RUN touch /var/log/cron.log

# Jalankan printenv (untuk inject env), tunggu MySQL siap, lalu jalankan ETL dan cron
CMD ["sh", "-c", "printenv > /etc/environment && \
    echo 'Waiting 60s for MySQL to be ready...' && sleep 60 && echo 'Running ETL...' && \
    python /app/main_elt.py && cron -f"]