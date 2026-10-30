from decimal import Decimal

import factory
from django.contrib.auth.models import User
from django.utils import timezone

from core.models import Account, Transaction


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
        django_get_or_create = ("username",)

    username = factory.Sequence(lambda number: f"user{number}")
    email = factory.LazyAttribute(lambda user: f"{user.username}@example.com")
    password = factory.django.Password("pass1234")


class AccountFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Account

    owner = factory.SubFactory(UserFactory)
    name = factory.Sequence(lambda number: f"Account {number}")
    balance = "0.00"


class TransactionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Transaction

    account = factory.SubFactory(AccountFactory)
    type = Transaction.INCOME
    amount = Decimal("10.00")
    category = "test"
    description = "desc"
    date = factory.LazyFunction(timezone.now)
