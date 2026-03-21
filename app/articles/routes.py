import re
from time import time
import sqlalchemy as sa
from flask import render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
from app import db
from app.articles import bp
from app.models import Article


def _slugify(text):
    """Convert title to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text or 'article'


CATEGORIES = ['general', 'tech', 'devops', 'kubernetes', 'java', 'python', 'career']


@bp.route('/')
def list_articles():
    category = request.args.get('category', '')
    page = request.args.get('page', 1, type=int)
    query = sa.select(Article).order_by(Article.created_at.desc())
    if category and category in CATEGORIES:
        query = query.where(Article.category == category)
    articles = db.paginate(query, page=page, per_page=10, error_out=False)
    next_url = url_for('articles.list_articles', page=articles.next_num, category=category) \
        if articles.has_next else None
    prev_url = url_for('articles.list_articles', page=articles.prev_num, category=category) \
        if articles.has_prev else None
    return render_template('articles/list.html',
                           title='Articles',
                           articles=articles.items,
                           categories=CATEGORIES,
                           selected_category=category,
                           next_url=next_url,
                           prev_url=prev_url)


@bp.route('/<slug>')
def article_detail(slug):
    article = db.first_or_404(sa.select(Article).where(Article.slug == slug))
    return render_template('articles/detail.html',
                           title=article.title,
                           article=article)


@bp.route('/new', methods=['GET', 'POST'])
@login_required
def new_article():
    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        summary = request.form.get('summary', '').strip()
        body = request.form.get('body', '').strip()
        category = request.form.get('category', 'general')
        if category not in CATEGORIES:
            category = 'general'
        if not title or not body:
            flash('Title and body are required.')
            return render_template('articles/form.html',
                                   title='New Article',
                                   categories=CATEGORIES)
        slug = _slugify(title)
        # Ensure slug uniqueness
        existing = db.session.scalar(sa.select(Article).where(Article.slug == slug))
        if existing:
            slug = f"{slug}-{int(time())}"
        article = Article(title=title, slug=slug, summary=summary,
                          body=body, category=category, author=current_user)
        db.session.add(article)
        db.session.commit()
        flash('Article published!')
        return redirect(url_for('articles.article_detail', slug=article.slug))
    return render_template('articles/form.html',
                           title='New Article',
                           categories=CATEGORIES)


@bp.route('/<slug>/edit', methods=['GET', 'POST'])
@login_required
def edit_article(slug):
    article = db.first_or_404(sa.select(Article).where(Article.slug == slug))
    if article.author != current_user:
        abort(403)
    if request.method == 'POST':
        article.title = request.form.get('title', article.title).strip()
        article.summary = request.form.get('summary', '').strip()
        article.body = request.form.get('body', article.body).strip()
        category = request.form.get('category', article.category)
        article.category = category if category in CATEGORIES else 'general'
        db.session.commit()
        flash('Article updated!')
        return redirect(url_for('articles.article_detail', slug=article.slug))
    return render_template('articles/form.html',
                           title='Edit Article',
                           article=article,
                           categories=CATEGORIES)
