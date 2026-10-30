import pytest
from decimal import Decimal
from core.models import Account
from core.tests.factories import AccountFactory, UserFactory


@pytest.mark.django_db
def test_list_accounts(auth_client, user):

    accounts = AccountFactory.create_batch(3, owner=user)

    AccountFactory(owner=UserFactory())

    resp = auth_client.get("/api/accounts/")
    assert resp.status_code == 200
    data = resp.json()

    assert len(data) == 3
    returned_ids = {a["id"] for a in data}
    assert set(a.id for a in accounts) == returned_ids


@pytest.mark.django_db
def test_create_account(auth_client, user):
    resp = auth_client.post(
        "/api/accounts/", {"name": "MyTest", "balance": "100.00"}, format="json"
    )
    assert resp.status_code == 201

    assert Account.objects.filter(
        owner=user, name="MyTest", balance=Decimal("100.00")
    ).exists()
