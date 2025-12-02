FROM python:3.9

# Set working directory
WORKDIR /app

# Install OS dependencies (rsync included by default in fat image, but add just in case)
RUN apt-get update && apt-get install -y \
    rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt
RUN pip install gunicorn

# Copy application code
COPY manage.py ./manage.py
COPY gutendex/ ./gutendex/
COPY books/ ./books/
COPY catalog_files/ ./catalog_files/
COPY static/ ./static/
COPY entrypoint.sh ./entrypoint.sh

# Prepare static/media dirs + entrypoint executable
RUN mkdir -p /app/static /app/media /app/staticfiles && \
    chmod +x /app/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
