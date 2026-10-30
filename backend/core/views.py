from datetime import datetime, date, timedelta
from calendar import monthrange

from django.db.models import Sum
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import (
    api_view,
    permission_classes,
    authentication_classes,
)
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from rest_framework_simplejwt.views import TokenObtainPairView
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .models import Account, Transaction
from .serializers import (
    RegisterSerializer,
    AccountSerializer,
    TransactionSerializer,
)


class LoginAPIView(TokenObtainPairView):
    """
    POST /api/login/ — будь-хто може запросити пару токенів
    """

    permission_classes = [permissions.AllowAny]
    authentication_classes = []


class RegisterAPIView(APIView):
    @swagger_auto_schema(
        request_body=RegisterSerializer,
        responses={201: openapi.Response("User created"), 400: "Validation Error"},
    )
    def post(self, request):
        permission_classes = [permissions.AllowAny]
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                {"message": "User created!"}, status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutAPIView(APIView):

    @swagger_auto_schema(
        operation_description="Logout user by blacklisting their refresh token.",
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            required=["refresh"],
            properties={
                "refresh": openapi.Schema(
                    type=openapi.TYPE_STRING, description="Refresh token to blacklist"
                )
            },
        ),
        responses={
            205: openapi.Response("Logged out successfully"),
            400: openapi.Response("Invalid or missing token"),
        },
    )
    def post(self, request):
        refresh_token = request.data.get("refresh")

        if not refresh_token:
            return Response({"error": "Refresh token is required"}, status=400)

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Logged out"}, status=205)
        except TokenError as e:
            return Response({"error": str(e)}, status=400)


class AccountViewSet(viewsets.ModelViewSet):
    serializer_class = AccountSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get_queryset(self):
        return Account.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = TransactionSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Transaction.objects.filter(account__owner=self.request.user)

    def create(self, request, *args, **kwargs):
        print("💥 TRANSACTION.CREATE request.data:", request.data)

        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print("💥 TRANSACTION.CREATE serializer.errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        return super().create(request, *args, **kwargs)


@api_view(["GET"])
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def analytics(request):
    """
    Повертає для поточного користувача
      - список рахунків з їх id, name і balance
      - загальний баланс (сума по всіх рахунках)
    """
    user = request.user
    qs = Account.objects.filter(owner=user)
    accounts = [{"id": a.id, "name": a.name, "balance": str(a.balance)} for a in qs]
    overall = sum(a.balance for a in qs)
    return Response({"accounts": accounts, "overall_balance": str(overall)})


@api_view(["GET"])
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def analytics_summary(request):
    """
    GET /api/analytics/summary/?start=YYYY-MM-DD&end=YYYY-MM-DD
    або ?period=this_month|this_week
    Опційно: &account_id=<id>&group_by=month
    """
    qs = Transaction.objects.filter(account__owner=request.user)

    # --- Парсимо date-range або period ---
    start = request.query_params.get("start")
    end = request.query_params.get("end")
    period = request.query_params.get("period")
    account_id = request.query_params.get("account_id")
    group_by = request.query_params.get("group_by")

    # shorthand
    if period == "this_month":
        today = date.today()
        start = today.replace(day=1).isoformat()
        end = today.isoformat()
    elif period == "this_week":
        today = date.today()
        start = (today - timedelta(days=today.weekday())).isoformat()
        end = today.isoformat()

    if not start or not end:
        return Response(
            {"detail": "`start` and `end` query params required"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    try:
        dt_start = datetime.fromisoformat(start)
        dt_end = datetime.fromisoformat(end)
    except ValueError:
        return Response(
            {"detail": "Dates must be ISO-8601, e.g. 2025-06-01"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Фільтруємо по date (а не timestamp!)
    qs = qs.filter(date__gte=dt_start, date__lte=dt_end)
    if account_id:
        qs = qs.filter(account_id=account_id)

    # Агрегація
    total_income = (
        qs.filter(type=Transaction.INCOME).aggregate(Sum("amount"))["amount__sum"] or 0
    )
    total_expense = (
        qs.filter(type=Transaction.EXPENSE).aggregate(Sum("amount"))["amount__sum"] or 0
    )
    net = total_income - total_expense

    result = {
        "income_sum": f"{total_income:.2f}",
        "expense_sum": f"{total_expense:.2f}",
        "net_sum": f"{net:.2f}",
        "currency": "USD",
    }

    # Деталізація по місяцях
    if group_by == "month":
        details = []
        year = dt_start.year
        for m in range(1, 13):
            first = datetime(year, m, 1)
            last_day = monthrange(year, m)[1]
            last = datetime(year, m, last_day, 23, 59, 59)
            subqs = Transaction.objects.filter(
                account__owner=request.user, date__gte=first, date__lte=last
            )
            if account_id:
                subqs = subqs.filter(account_id=account_id)
            inc = (
                subqs.filter(type=Transaction.INCOME).aggregate(Sum("amount"))[
                    "amount__sum"
                ]
                or 0
            )
            exp = (
                subqs.filter(type=Transaction.EXPENSE).aggregate(Sum("amount"))[
                    "amount__sum"
                ]
                or 0
            )
            details.append(
                {
                    "month": m,
                    "income": f"{inc:.2f}",
                    "expense": f"{exp:.2f}",
                    "net": f"{(inc - exp):.2f}",
                }
            )
        result["by_month"] = details

    return Response(result)
