from datetime import date, timedelta

from django.db.models import Sum
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Account, Transaction
from .serializers import (
    AccountSerializer,
    RegisterSerializer,
    TransactionSerializer,
)


class LoginAPIView(TokenObtainPairView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []


class RegisterAPIView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    @swagger_auto_schema(
        request_body=RegisterSerializer,
        responses={201: openapi.Response("User created"), 400: "Validation Error"},
    )
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
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
        except TokenError as error:
            return Response({"error": str(error)}, status=400)


class AccountViewSet(viewsets.ModelViewSet):
    serializer_class = AccountSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Account.objects.none()
        return Account.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = TransactionSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Transaction.objects.none()
        return Transaction.objects.filter(account__owner=self.request.user)


@api_view(["GET"])
def analytics(request):
    """Accounts of the current user with their balances, plus the overall balance."""
    accounts = Account.objects.filter(owner=request.user)
    return Response(
        {
            "accounts": [
                {
                    "id": account.id,
                    "name": account.name,
                    "balance": str(account.balance),
                }
                for account in accounts
            ],
            "overall_balance": str(sum(account.balance for account in accounts)),
        }
    )


def total_amount(transactions, transaction_type):
    totals = transactions.filter(type=transaction_type).aggregate(total=Sum("amount"))
    return totals["total"] or 0


@api_view(["GET"])
def analytics_summary(request):
    """
    Income, expense and net for a date range.

    ?start=YYYY-MM-DD&end=YYYY-MM-DD or ?period=this_month|this_week,
    optionally &account_id=<id>&group_by=month.
    """
    transactions = Transaction.objects.filter(account__owner=request.user)

    start = request.query_params.get("start")
    end = request.query_params.get("end")
    period = request.query_params.get("period")
    account_id = request.query_params.get("account_id")
    group_by = request.query_params.get("group_by")

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
        start_date = date.fromisoformat(start)
        end_date = date.fromisoformat(end)
    except ValueError:
        return Response(
            {"detail": "Dates must be ISO-8601, e.g. 2025-06-01"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if account_id and not account_id.isdigit():
        return Response(
            {"detail": "`account_id` must be a number"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Filter by the user-set date, not the creation timestamp. Both ends are inclusive.
    if account_id:
        transactions = transactions.filter(account_id=account_id)
    transactions_in_range = transactions.filter(
        date__date__range=(start_date, end_date)
    )

    total_income = total_amount(transactions_in_range, Transaction.INCOME)
    total_expense = total_amount(transactions_in_range, Transaction.EXPENSE)
    net = total_income - total_expense

    result = {
        "income_sum": f"{total_income:.2f}",
        "expense_sum": f"{total_expense:.2f}",
        "net_sum": f"{net:.2f}",
        "currency": "USD",
    }

    if group_by == "month":
        by_month = []
        for month in range(1, 13):
            transactions_in_month = transactions.filter(
                date__year=start_date.year, date__month=month
            )
            income = total_amount(transactions_in_month, Transaction.INCOME)
            expense = total_amount(transactions_in_month, Transaction.EXPENSE)
            by_month.append(
                {
                    "month": month,
                    "income": f"{income:.2f}",
                    "expense": f"{expense:.2f}",
                    "net": f"{(income - expense):.2f}",
                }
            )
        result["by_month"] = by_month

    return Response(result)
