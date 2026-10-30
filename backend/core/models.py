from django.conf import settings
from django.db import models
from django.utils import timezone


class Account(models.Model):
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="accounts"
    )
    name = models.CharField(max_length=100)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)


class Transaction(models.Model):
    INCOME = "IN"
    EXPENSE = "EX"
    TYPE_CHOICES = [(INCOME, "Income"), (EXPENSE, "Expense")]

    account = models.ForeignKey(
        Account, on_delete=models.CASCADE, related_name="transactions"
    )
    type = models.CharField(max_length=2, choices=TYPE_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.CharField(max_length=50, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    description = models.TextField(blank=True)
    date = models.DateTimeField(default=timezone.now)
