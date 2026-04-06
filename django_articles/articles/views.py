import re
import time
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from .forms import ArticleForm, CATEGORIES
from .models import Article


def _slugify(text):
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text or 'article'


def list_articles(request):
    category = request.GET.get('category', '')
    page = request.GET.get('page', 1)

    qs = Article.objects.all().order_by('-created_at')
    if category in CATEGORIES:
        qs = qs.filter(category=category)

    pager = Paginator(qs, 10)
    page_obj = pager.get_page(page)

    context = {
        'title': 'Articles',
        'articles': page_obj.object_list,
        'categories': CATEGORIES,
        'selected_category': category,
        'page_obj': page_obj,
    }
    return render(request, 'articles/list.html', context)


def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug)
    return render(request, 'articles/detail.html', {'article': article, 'title': article.title})


@login_required
def new_article(request):
    if request.method == 'POST':
        form = ArticleForm(request.POST)
        if form.is_valid():
            article = form.save(commit=False)
            article.slug = _slugify(article.title)
            if Article.objects.filter(slug=article.slug).exists():
                article.slug = f"{article.slug}-{int(time.time())}"
            article.author_id = request.user.id
            article.created_at = timezone.now()
            article.updated_at = timezone.now()
            article.save()
            messages.success(request, 'Article published!')
            return redirect('articles:detail', slug=article.slug)
    else:
        form = ArticleForm()

    return render(request, 'articles/form.html', {'title': 'New Article', 'form': form})


@login_required
def edit_article(request, slug):
    article = get_object_or_404(Article, slug=slug)
    if article.author_id != request.user.id:
        return HttpResponseForbidden('You do not have permission to edit this article.')

    if request.method == 'POST':
        form = ArticleForm(request.POST, instance=article)
        if form.is_valid():
            obj = form.save(commit=False)
            obj.updated_at = timezone.now()
            obj.save()
            messages.success(request, 'Article updated!')
            return redirect('articles:detail', slug=obj.slug)
    else:
        form = ArticleForm(instance=article)

    return render(request, 'articles/form.html', {'title': 'Edit Article', 'form': form, 'article': article})
