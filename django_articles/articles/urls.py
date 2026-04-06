from django.urls import path
from . import views

app_name = 'articles'

urlpatterns = [
    path('', views.list_articles, name='list'),
    path('new/', views.new_article, name='new'),
    path('<slug:slug>/', views.article_detail, name='detail'),
    path('<slug:slug>/edit/', views.edit_article, name='edit'),
]
