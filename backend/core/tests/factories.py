from decimal import Decimal

import factory
from django.utils import timezone
from django.contrib.auth.models import User
from core.models import Account, Transaction


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
        django_get_or_create = ("username",)

    username = factory.Sequence(lambda n: f"user{n}")
    email = factory.LazyAttribute(lambda o: f"{o.username}@example.com")
    password = factory.PostGenerationMethodCall("set_password", "pass1234")


class AccountFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Account

    owner = factory.SubFactory(UserFactory)
    name = factory.Sequence(lambda n: f"Account {n}")
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
