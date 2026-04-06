from django.contrib import admin
from django.http import HttpResponseRedirect
from django.urls import include, path


def home(_request):
    return HttpResponseRedirect('/articles/')


urlpatterns = [
    path('admin/', admin.site.urls),
    path('articles/', include('articles.urls')),
    path('', home),
]
