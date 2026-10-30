import pytest
from decimal import Decimal
from core.models import Account, Transaction
from core.tests.factories import AccountFactory, TransactionFactory


@pytest.mark.django_db
def test_add_transaction_updates_balance(auth_client, user):
    account = AccountFactory(owner=user, balance="50.00")
    payload = {
        "account": account.id,
        "type": Transaction.INCOME,
        "amount": "25.00",
        "category": "",
        "description": "",
        "date": "2025-06-19T00:00:00Z",
    }
    resp = auth_client.post("/api/transactions/", payload, format="json")
    assert resp.status_code == 201

    account.refresh_from_db()
    assert account.balance == Decimal("75.00")


@pytest.mark.django_db
def test_transaction_invalid_account(auth_client):
    payload = {
        "account": 999,
        "type": Transaction.INCOME,
        "amount": "10.00",
        "category": "",
        "description": "",
        "date": "2025-06-19T00:00:00Z",
    }
    resp = auth_client.post("/api/transactions/", payload, format="json")
    assert resp.status_code == 400
    json = resp.json()
    assert "account" in json


@pytest.mark.django_db
def test_cannot_add_transaction_to_another_users_account(auth_client):
    foreign = AccountFactory(balance="100.00")
    payload = {
        "account": foreign.id,
        "type": Transaction.EXPENSE,
        "amount": "99.00",
        "date": "2025-06-19T00:00:00Z",
    }
    resp = auth_client.post("/api/transactions/", payload, format="json")
    assert resp.status_code == 400
    assert "account" in resp.json()

    foreign.refresh_from_db()
    assert foreign.balance == Decimal("100.00")


@pytest.mark.django_db
def test_cannot_move_transaction_to_another_users_account(auth_client, user):
    tx = TransactionFactory(account=AccountFactory(owner=user))
    foreign = AccountFactory()

    resp = auth_client.patch(
        f"/api/transactions/{tx.id}/", {"account": foreign.id}, format="json"
    )
    assert resp.status_code == 400
    tx.refresh_from_db()
    assert tx.account.owner == user
