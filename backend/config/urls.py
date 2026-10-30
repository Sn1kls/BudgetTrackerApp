from django.contrib import admin
from django.urls import path, re_path, include
from rest_framework import permissions
from rest_framework.routers import DefaultRouter
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

from core.views import RegisterAPIView, LogoutAPIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


schema_view = get_schema_view(
    openapi.Info(
        title="Budget Tracker API",
        default_version="v1",
        description="Документація до API",
        terms_of_service="https://www.google.com/policies/terms/",
        contact=openapi.Contact(email="contact@example.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)


from core.views import (
    AccountViewSet,
    TransactionViewSet,
    RegisterAPIView,
    LogoutAPIView,
    LoginAPIView,
    analytics,
    analytics_summary,
)
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r"accounts", AccountViewSet, basename="account")
router.register(r"transactions", TransactionViewSet, basename="transaction")

urlpatterns = [
    path("api/register/", RegisterAPIView.as_view(), name="register"),
    path("api/login/", LoginAPIView.as_view(), name="token_obtain_pair"),
    path("api/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/logout/", LogoutAPIView.as_view(), name="logout"),
    path("api/", include(router.urls)),
    path("swagger/", schema_view.with_ui("swagger"), name="swagger"),
    path("api/analytics/", analytics, name="analytics"),
    path("api/analytics/summary/", analytics_summary, name="analytics-summary"),
]
