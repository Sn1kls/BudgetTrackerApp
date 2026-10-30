import pytest


@pytest.mark.django_db
def test_successful_login(api_client, user):
    resp = api_client.post(
        "/api/login/",
        {"username": user.username, "password": "pass1234"},
        format="json",
    )
    assert resp.status_code == 200
    json = resp.json()
    assert "access" in json and "refresh" in json


@pytest.mark.django_db
def test_expired_access_token(expired_client):
    resp = expired_client.get("/api/accounts/")
    assert resp.status_code == 401

    assert (
        "token_not_valid" in resp.json().get("code", "")
        or "expired" in resp.json().get("detail", "").lower()
    )


@pytest.mark.django_db
def test_logout_requires_authentication(api_client):
    resp = api_client.post("/api/logout/", {"refresh": "x"}, format="json")
    assert resp.status_code == 401


def test_unknown_host_is_rejected(client, settings):
    settings.ALLOWED_HOSTS = ["localhost"]
    resp = client.get("/swagger/", HTTP_HOST="evil.example")
    assert resp.status_code == 400
