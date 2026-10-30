import pytest
from django.contrib.auth.models import User


@pytest.mark.django_db
def test_successful_login(api_client, user):
    response = api_client.post(
        "/api/login/",
        {"username": user.username, "password": "pass1234"},
        format="json",
    )
    assert response.status_code == 200
    body = response.json()
    assert "access" in body and "refresh" in body


@pytest.mark.django_db
def test_expired_access_token(expired_client):
    response = expired_client.get("/api/accounts/")
    assert response.status_code == 401

    assert (
        "token_not_valid" in response.json().get("code", "")
        or "expired" in response.json().get("detail", "").lower()
    )


@pytest.mark.django_db
def test_logout_requires_authentication(api_client):
    response = api_client.post("/api/logout/", {"refresh": "x"}, format="json")
    assert response.status_code == 401


def test_unknown_host_is_rejected(client, settings):
    settings.ALLOWED_HOSTS = ["localhost"]
    response = client.get("/swagger/", HTTP_HOST="evil.example")
    assert response.status_code == 400


@pytest.mark.django_db
def test_register_creates_user(api_client):
    response = api_client.post(
        "/api/register/",
        {
            "username": "maria",
            "email": "maria@example.com",
            "password": "c0rrect-Horse",
        },
        format="json",
    )
    assert response.status_code == 201
    assert User.objects.get(username="maria").check_password("c0rrect-Horse")


@pytest.mark.django_db
@pytest.mark.parametrize("password", ["1", "password", "12345678"])
def test_register_rejects_weak_password(api_client, password):
    response = api_client.post(
        "/api/register/",
        {"username": "maria", "email": "maria@example.com", "password": password},
        format="json",
    )
    assert response.status_code == 400
    assert "password" in response.json()
    assert not User.objects.filter(username="maria").exists()


@pytest.mark.django_db
def test_swagger_schema_builds_without_errors(api_client, caplog):
    response = api_client.get("/swagger/?format=openapi")
    assert response.status_code == 200
    assert "raised exception during schema generation" not in caplog.text
