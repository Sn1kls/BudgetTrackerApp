from datetime import datetime, timezone
from decimal import Decimal

import pytest

from core.models import Transaction
from core.tests.factories import AccountFactory, TransactionFactory


def at(day, hour=0):
    return datetime(2025, 6, day, hour, tzinfo=timezone.utc)


@pytest.mark.django_db
def test_summary_counts_the_whole_end_day(auth_client, user):
    account = AccountFactory(owner=user)
    TransactionFactory(account=account, type=Transaction.INCOME, amount=Decimal("100.00"), date=at(1))
    TransactionFactory(account=account, type=Transaction.EXPENSE, amount=Decimal("30.00"), date=at(19, hour=18))
    TransactionFactory(account=account, type=Transaction.EXPENSE, amount=Decimal("5.00"), date=at(20))

    resp = auth_client.get("/api/analytics/summary/?start=2025-06-01&end=2025-06-19")

    assert resp.status_code == 200
    assert resp.json() == {
        "income_sum": "100.00",
        "expense_sum": "30.00",
        "net_sum": "70.00",
        "currency": "USD",
    }


@pytest.mark.django_db
def test_summary_ignores_other_users_transactions(auth_client, user):
    TransactionFactory(amount=Decimal("50.00"), date=at(5))

    resp = auth_client.get("/api/analytics/summary/?start=2025-06-01&end=2025-06-30")

    assert resp.json()["income_sum"] == "0.00"


@pytest.mark.django_db
@pytest.mark.parametrize(
    "query",
    [
        "start=2025-06-01",
        "start=june&end=july",
        "start=2025-06-01&end=2025-06-30&account_id=abc",
    ],
)
def test_summary_rejects_bad_query(auth_client, query):
    resp = auth_client.get(f"/api/analytics/summary/?{query}")
    assert resp.status_code == 400


@pytest.mark.django_db
def test_summary_by_month(auth_client, user):
    account = AccountFactory(owner=user)
    TransactionFactory(account=account, amount=Decimal("40.00"), date=at(30, hour=23))

    resp = auth_client.get(
        "/api/analytics/summary/?start=2025-06-01&end=2025-06-30&group_by=month"
    )

    by_month = resp.json()["by_month"]
    assert len(by_month) == 12
    assert by_month[5] == {"month": 6, "income": "40.00", "expense": "0.00", "net": "40.00"}
    assert by_month[6]["income"] == "0.00"
