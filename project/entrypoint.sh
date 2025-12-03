#!/bin/sh
set -e

echo "=== [backend] Waiting for Postgres at ${DATABASE_HOST}:${DATABASE_PORT} ==="
# custom healthcheck for Postgres
python - <<EOF
import os, time, psycopg2

host = os.environ.get("DATABASE_HOST", "db")
port = int(os.environ.get("DATABASE_PORT", "5432"))
dbname = os.environ.get("DATABASE_NAME", "gutendex")
user = os.environ.get("DATABASE_USER", "gutendex")
password = os.environ.get("DATABASE_PASSWORD", "gutendex")

for i in range(30):
    try:
        conn = psycopg2.connect(
            dbname=dbname, user=user, password=password,
            host=host, port=port
        )
        conn.close()
        print("DB is ready.")
        break
    except Exception:
        print("DB not ready yet ({i}), retrying...", flush=True)
        time.sleep(2)
else:
    raise SystemExit("ERROR: Database not available.")
EOF

# manage.py commands [migration, catalog load, collectstatic, runserver]
echo "=== [backend] Running migrations ==="
python manage.py migrate --noinput

echo "=== [backend] Checking if catalog is already loaded ==="
python manage.py shell <<EOF
from books.models import Book
from django.core.management import call_command
import os

if Book.objects.exists():
    print("Catalog already present; skipping updatecatalog.")
else:
    print("Catalog empty; preparing folder structure...")

    base = "/app/catalog_files/tmp/cache"
    for d in ("epub", "rdf", "images"):
        os.makedirs(os.path.join(base, d), exist_ok=True)

    print("=== [backend] Running updatecatalog ===")
    call_command("updatecatalog")
EOF

echo "=== [backend] Collecting static files ==="
python manage.py collectstatic --noinput

HOST="${BIND_HOST:-0.0.0.0}"
PORT="${BIND_PORT:-8000}"
echo "=== [backend] Starting Django dev server on ${HOST}:${PORT} ==="
python manage.py runserver "${HOST}:${PORT}"
