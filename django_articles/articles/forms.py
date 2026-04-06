from django import forms
from .models import Article


CATEGORIES = ['general', 'tech', 'devops', 'kubernetes', 'java', 'python', 'career']


class ArticleForm(forms.ModelForm):
    category = forms.ChoiceField(choices=[(c, c.capitalize()) for c in CATEGORIES])

    class Meta:
        model = Article
        fields = ['title', 'category', 'summary', 'body']
        widgets = {
            'summary': forms.TextInput(attrs={'placeholder': 'One-line description (optional)'}),
            'body': forms.Textarea(attrs={'rows': 16}),
        }
