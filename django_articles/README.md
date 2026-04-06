Django Articles Vertical Slice

This subproject is a parallel Django service that only handles articles.
It is designed to coexist with the existing Flask app during migration.

Quick start

1) Install dependencies from repository root:
   pip install -r requirements.txt

2) Run Django admin migrations (for auth/admin/session tables):
   cd django_articles
   python manage.py migrate

3) Create an admin user:
   python manage.py createsuperuser

4) Run server:
   python manage.py runserver 0.0.0.0:8001

Run with Docker Compose (recommended for coexistence with Flask)

1) From repository root:
   docker compose up -d db web django_articles

2) Verify:
   curl -I http://localhost:8001/articles/

Routes

- /articles/           list + category filter + pagination
- /articles/<slug>/    detail
- /articles/new/       create (login required)
- /articles/<slug>/edit/ edit (author only)
- /admin/              admin UI

Database notes

- Article table maps to existing table name: article
- author_id is preserved as integer to reduce coupling in phase 1
- Flask user names are displayed via read-only lookup on table: user

Suggested gateway split

- Route /articles/* to this Django service
- Keep all other routes on Flask until later phases
- Nginx split example is in deployment/nginx/yaonet
