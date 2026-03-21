"""articles table

Revision ID: 0f12d7c2b7a1
Revises: 834b1a697901
Create Date: 2026-03-20 23:35:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0f12d7c2b7a1'
down_revision = '834b1a697901'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'article',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('slug', sa.String(length=220), nullable=False),
        sa.Column('summary', sa.String(length=500), nullable=True),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('category', sa.String(length=64), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('author_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['author_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_article_title'), 'article', ['title'], unique=False)
    op.create_index(op.f('ix_article_slug'), 'article', ['slug'], unique=True)
    op.create_index(op.f('ix_article_category'), 'article', ['category'], unique=False)
    op.create_index(op.f('ix_article_created_at'), 'article', ['created_at'], unique=False)
    op.create_index(op.f('ix_article_author_id'), 'article', ['author_id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_article_author_id'), table_name='article')
    op.drop_index(op.f('ix_article_created_at'), table_name='article')
    op.drop_index(op.f('ix_article_category'), table_name='article')
    op.drop_index(op.f('ix_article_slug'), table_name='article')
    op.drop_index(op.f('ix_article_title'), table_name='article')
    op.drop_table('article')
