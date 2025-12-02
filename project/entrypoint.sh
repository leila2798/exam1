#!/bin/sh
set -e

echo "=== [backend] Waiting for Postgres at ${DATABASE_HOST}:${DATABASE_PORT} ==="

python - <<EOF
import os, time
import psycopg2

host = os.environ.get("DATABASE_HOST", "db")
port = int(os.environ.get("DATABASE_PORT", "5432"))
dbname = os.environ.get("DATABASE_NAME", "gutendex")
user = os.environ.get("DATABASE_USER", "gutendex")
password = os.environ.get("DATABASE_PASSWORD", "gutendex")

for i in range(30):
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port,
        )
        conn.close()
        print("DB is ready.")
        break
    except Exception as e:
        print(f"DB not ready yet ({i}), retrying...", flush=True)
        time.sleep(2)
else:
    raise SystemExit("ERROR: Database not available after waiting.")
EOF

echo "=== [backend] Running migrations ==="
python manage.py migrate --noinput

echo "=== [backend] Checking if catalog is already loaded ==="
python manage.py shell <<EOF
from books.models import Book
from django.core.management import call_command

if Book.objects.exists():
    print("Catalog already present; skipping updatecatalog.")
else:
    print("Catalog empty; running updatecatalog using local RDF files...")
    call_command("updatecatalog")
EOF

echo "=== [backend] Collecting static files ==="
python manage.py collectstatic --noinput

echo "=== [backend] Starting Gunicorn ==="
exec gunicorn gutendex.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3
