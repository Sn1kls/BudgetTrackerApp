from datetime import timedelta

import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from core.tests.factories import UserFactory


@pytest.fixture
def user(db):
    return UserFactory()  # password: pass1234


@pytest.fixture
def auth_client(db, user):
    client = APIClient()
    access = RefreshToken.for_user(user).access_token
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return client


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def expired_client(db, user):
    client = APIClient()
    token = RefreshToken.for_user(user).access_token
    token.set_exp(lifetime=timedelta(days=-1))
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client
