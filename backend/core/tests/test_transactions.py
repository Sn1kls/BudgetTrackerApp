from decimal import Decimal

import pytest

from core.models import Transaction
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
    response = auth_client.post("/api/transactions/", payload, format="json")
    assert response.status_code == 201

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
    response = auth_client.post("/api/transactions/", payload, format="json")
    assert response.status_code == 400
    body = response.json()
    assert "account" in body


@pytest.mark.django_db
def test_cannot_add_transaction_to_another_users_account(auth_client):
    foreign = AccountFactory(balance="100.00")
    payload = {
        "account": foreign.id,
        "type": Transaction.EXPENSE,
        "amount": "99.00",
        "date": "2025-06-19T00:00:00Z",
    }
    response = auth_client.post("/api/transactions/", payload, format="json")
    assert response.status_code == 400
    assert "account" in response.json()

    foreign.refresh_from_db()
    assert foreign.balance == Decimal("100.00")


@pytest.mark.django_db
def test_cannot_move_transaction_to_another_users_account(auth_client, user):
    transaction = TransactionFactory(account=AccountFactory(owner=user))
    foreign = AccountFactory()

    response = auth_client.patch(
        f"/api/transactions/{transaction.id}/", {"account": foreign.id}, format="json"
    )
    assert response.status_code == 400
    transaction.refresh_from_db()
    assert transaction.account.owner == user


@pytest.mark.django_db
@pytest.mark.parametrize("amount", ["-50.00", "0.00"])
def test_amount_must_be_positive(auth_client, user, amount):
    account = AccountFactory(owner=user, balance="0.00")
    payload = {
        "account": account.id,
        "type": Transaction.EXPENSE,
        "amount": amount,
        "date": "2025-06-19T00:00:00Z",
    }
    response = auth_client.post("/api/transactions/", payload, format="json")
    assert response.status_code == 400
    assert "amount" in response.json()


@pytest.mark.django_db
def test_editing_amount_adjusts_balance(auth_client, user):
    account = AccountFactory(owner=user, balance="0.00")
    transaction = TransactionFactory(
        account=account, type=Transaction.INCOME, amount=Decimal("10.00")
    )

    response = auth_client.patch(
        f"/api/transactions/{transaction.id}/", {"amount": "25.00"}, format="json"
    )
    assert response.status_code == 200
    account.refresh_from_db()
    assert account.balance == Decimal("25.00")


@pytest.mark.django_db
def test_moving_transaction_between_accounts_moves_the_money(auth_client, user):
    source = AccountFactory(owner=user, balance="0.00")
    target = AccountFactory(owner=user, balance="0.00")
    transaction = TransactionFactory(
        account=source, type=Transaction.INCOME, amount=Decimal("10.00")
    )

    response = auth_client.patch(
        f"/api/transactions/{transaction.id}/", {"account": target.id}, format="json"
    )
    assert response.status_code == 200
    source.refresh_from_db()
    target.refresh_from_db()
    assert source.balance == Decimal("0.00")
    assert target.balance == Decimal("10.00")


@pytest.mark.django_db
def test_deleting_transaction_reverts_balance(auth_client, user):
    account = AccountFactory(owner=user, balance="0.00")
    transaction = TransactionFactory(
        account=account, type=Transaction.EXPENSE, amount=Decimal("10.00")
    )

    response = auth_client.delete(f"/api/transactions/{transaction.id}/")
    assert response.status_code == 204
    account.refresh_from_db()
    assert account.balance == Decimal("0.00")
