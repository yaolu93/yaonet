from django.contrib import admin
from .models import Article


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'category', 'author_id', 'created_at', 'updated_at')
    list_filter = ('category',)
    search_fields = ('title', 'summary', 'body', 'slug')
    prepopulated_fields = {'slug': ('title',)}
