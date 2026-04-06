from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name='Article',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(db_index=True, max_length=200)),
                ('slug', models.SlugField(db_index=True, max_length=220, unique=True)),
                ('summary', models.CharField(blank=True, max_length=500)),
                ('body', models.TextField()),
                ('category', models.CharField(db_index=True, default='general', max_length=64)),
                ('created_at', models.DateTimeField(db_index=True)),
                ('updated_at', models.DateTimeField()),
                ('author_id', models.IntegerField(db_index=True)),
            ],
            options={
                'db_table': 'article',
                'ordering': ['-created_at'],
            },
        ),
    ]
