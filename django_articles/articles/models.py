from django.db import models
from django.utils import timezone


class FlaskUser(models.Model):
    id = models.BigAutoField(primary_key=True)
    username = models.CharField(max_length=64)

    class Meta:
        managed = False
        db_table = 'user'

    def __str__(self):
        return self.username


class Article(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(max_length=220, unique=True, db_index=True)
    summary = models.CharField(max_length=500, blank=True)
    body = models.TextField()
    category = models.CharField(max_length=64, db_index=True, default='general')
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    updated_at = models.DateTimeField(default=timezone.now)
    author_id = models.IntegerField(db_index=True)

    class Meta:
        db_table = 'article'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def author_username(self):
        try:
            user = FlaskUser.objects.filter(id=self.author_id).only('username').first()
            return user.username if user else f'user#{self.author_id}'
        except Exception:
            return f'user#{self.author_id}'
