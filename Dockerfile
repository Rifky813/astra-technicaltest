FROM python:3.12-slim

# Install cron
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

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

# Jalankan printenv (untuk inject env) lalu nyalakan cron
CMD ["sh", "-c", "printenv > /etc/environment && cron -f"]