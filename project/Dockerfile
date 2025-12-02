#python 3.9-slim
FROM python:3.9

#no pyc generated 
# ENV PYTHONDONTWRITEBYTECODE=1
# see logs in stdout/stderr immediately
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# System deps for Postgres client libs (psycopg2, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*


COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# Copy only what we need (no `COPY . .`)
COPY manage.py ./manage.py
COPY gutendex/ ./gutendex/
COPY books/ ./books/
COPY catalog_files/ ./catalog_files/
COPY static/ ./static/
COPY entrypoint.sh ./entrypoint.sh

RUN mkdir -p /app/static /app/media \
    && chmod +x /app/entrypoint.sh

CMD ["./entrypoint.sh"]