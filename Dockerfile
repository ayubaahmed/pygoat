# Use a supported, slim Python base on Debian Bookworm (current); avoids EOL repo errors
FROM python:3.11-slim-bookworm

# Minimize Python runtime noise and ensure unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# All app files will live here
WORKDIR /app

# Install OS build deps (for compiling wheels like psycopg2)
# - build-essential,gcc: compile native extensions
# - libpq-dev: PostgreSQL client headers for psycopg2
# - netcat-traditional: optional, handy for wait-for-db scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc libpq-dev netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency manifest first to leverage Docker layer caching
COPY requirements.txt .

# Upgrade pip and install Python deps
# If you use psycopg2 and hit build issues, consider replacing with psycopg2-binary in requirements.txt
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app source
COPY . .

# Run DB migrations at build-time so the image is ready-to-run
# Remove this if you prefer to run migrations at container start instead
RUN python manage.py migrate --noinput

# Expose Django/Gunicorn port
EXPOSE 8000

# Start Gunicorn app server
# Ensure "gunicorn" is present in requirements.txt
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "pygoat.wsgi"]
