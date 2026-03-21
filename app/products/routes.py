import requests
from flask import render_template, current_app, abort, request, redirect, \
    url_for, flash
from flask_login import current_user, login_required
from app import db
from app.products import bp


def _products_api_url(path=''):
    """Build URL for the Spring Boot products service."""
    base = current_app.config.get('PRODUCTS_SERVICE_URL', 'http://localhost:8080')
    return f"{base.rstrip('/')}/api/products{path}"


def _auth_headers():
    """Forward Flask-issued user token to Spring Boot service."""
    token = current_user.get_token()
    db.session.commit()
    return {
        'Authorization': f'Bearer {token}',
        'X-Yaonet-User-Id': str(current_user.id),
        'Content-Type': 'application/json',
    }


@bp.route('/')
def list_products():
    try:
        resp = requests.get(_products_api_url(), timeout=5)
        resp.raise_for_status()
        products = resp.json()
    except Exception:
        products = []
        current_app.logger.warning('Products service unavailable')
    return render_template('products/list.html',
                           title='Products',
                           products=products)


@bp.route('/<int:product_id>')
def product_detail(product_id):
    try:
        resp = requests.get(_products_api_url(f'/{product_id}'), timeout=5)
        if resp.status_code == 404:
            abort(404)
        resp.raise_for_status()
        product = resp.json()
    except requests.exceptions.RequestException:
        abort(503)
    return render_template('products/detail.html',
                           title=product.get('name', 'Product'),
                           product=product)


@bp.route('/manage')
@login_required
def manage_products():
    try:
        resp = requests.get(_products_api_url(), timeout=5)
        resp.raise_for_status()
        products = resp.json()
    except Exception:
        products = []
        flash('Products service unavailable')
    return render_template('products/manage.html',
                           title='Manage Products',
                           products=products)


@bp.route('/new', methods=['GET', 'POST'])
@login_required
def create_product():
    if request.method == 'POST':
        payload = {
            'name': request.form.get('name', '').strip(),
            'description': request.form.get('description', '').strip(),
            'price': float(request.form.get('price', '0') or 0),
            'stock': int(request.form.get('stock', '0') or 0),
            'imageUrl': request.form.get('image_url', '').strip(),
        }
        if not payload['name']:
            flash('Name is required')
            return render_template('products/form.html', title='New Product')
        try:
            resp = requests.post(
                _products_api_url(), json=payload, headers=_auth_headers(), timeout=5)
            resp.raise_for_status()
            flash('Product created')
            return redirect(url_for('products.manage_products'))
        except requests.exceptions.RequestException:
            flash('Failed to create product')
    return render_template('products/form.html', title='New Product')


@bp.route('/<int:product_id>/edit', methods=['GET', 'POST'])
@login_required
def edit_product(product_id):
    if request.method == 'POST':
        payload = {
            'name': request.form.get('name', '').strip(),
            'description': request.form.get('description', '').strip(),
            'price': float(request.form.get('price', '0') or 0),
            'stock': int(request.form.get('stock', '0') or 0),
            'imageUrl': request.form.get('image_url', '').strip(),
        }
        try:
            resp = requests.put(
                _products_api_url(f'/{product_id}'),
                json=payload,
                headers=_auth_headers(),
                timeout=5,
            )
            resp.raise_for_status()
            flash('Product updated')
            return redirect(url_for('products.manage_products'))
        except requests.exceptions.RequestException:
            flash('Failed to update product')

    try:
        resp = requests.get(_products_api_url(f'/{product_id}'), timeout=5)
        if resp.status_code == 404:
            abort(404)
        resp.raise_for_status()
        product = resp.json()
    except requests.exceptions.RequestException:
        abort(503)

    return render_template('products/form.html',
                           title='Edit Product',
                           product=product)


@bp.route('/<int:product_id>/delete', methods=['POST'])
@login_required
def delete_product(product_id):
    try:
        resp = requests.delete(
            _products_api_url(f'/{product_id}'), headers=_auth_headers(), timeout=5)
        if resp.status_code not in (200, 204):
            resp.raise_for_status()
        flash('Product deleted')
    except requests.exceptions.RequestException:
        flash('Failed to delete product')
    return redirect(url_for('products.manage_products'))
