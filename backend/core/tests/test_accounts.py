from decimal import Decimal

import pytest

from core.models import Account
from core.tests.factories import AccountFactory, UserFactory


@pytest.mark.django_db
def test_list_accounts(auth_client, user):

    accounts = AccountFactory.create_batch(3, owner=user)

    AccountFactory(owner=UserFactory())

    response = auth_client.get("/api/accounts/")
    assert response.status_code == 200
    data = response.json()

    assert len(data) == 3
    returned_ids = {account["id"] for account in data}
    assert {account.id for account in accounts} == returned_ids


@pytest.mark.django_db
def test_create_account(auth_client, user):
    response = auth_client.post(
        "/api/accounts/", {"name": "MyTest", "balance": "100.00"}, format="json"
    )
    assert response.status_code == 201

    assert Account.objects.filter(
        owner=user, name="MyTest", balance=Decimal("100.00")
    ).exists()
