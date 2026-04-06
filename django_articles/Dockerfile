FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY django_articles /app/django_articles

WORKDIR /app/django_articles

EXPOSE 8001

CMD ["sh", "-c", "python manage.py migrate --fake-initial && gunicorn project.wsgi:application -b 0.0.0.0:8001 -w 2"]
