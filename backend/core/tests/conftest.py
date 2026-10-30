# core/tests/conftest.py
import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from core.tests.factories import UserFactory

@pytest.fixture
def user(db):
    return UserFactory()  # пароль “pass1234” as per factory

@pytest.fixture
def auth_client(db, user):
    """
    Клієнт уже залогінений – даємо дійсний access token
    """
    client = APIClient()
    access = RefreshToken.for_user(user).access_token
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return client

@pytest.fixture
def api_client():
    """
    Простіший APIClient без токена – для реєстрації / логіну
    """
    return APIClient()

@pytest.fixture
def expired_client(db, user):
    """
    Клієнт із простроченим токеном
    """
    client = APIClient()
    token = RefreshToken.for_user(user).access_token
    token.set_exp(lifetime=timedelta(days=-1))
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client
