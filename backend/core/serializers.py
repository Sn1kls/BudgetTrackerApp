from datetime import UTC
from decimal import Decimal

from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import Account, Transaction


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ["username", "email", "password"]

    def validate(self, attrs):
        user = User(username=attrs["username"], email=attrs.get("email", ""))
        try:
            validate_password(attrs["password"], user)
        except DjangoValidationError as error:
            raise serializers.ValidationError({"password": list(error.messages)})
        return attrs

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class AccountSerializer(serializers.ModelSerializer):
    balance = serializers.DecimalField(
        max_digits=12, decimal_places=2, coerce_to_string=True
    )

    class Meta:
        model = Account
        fields = ["id", "name", "balance", "owner"]
        read_only_fields = ("owner",)


class TransactionSerializer(serializers.ModelSerializer):
    # The iOS client parses dates as ISO-8601 UTC with a trailing "Z".
    date = serializers.DateTimeField(
        format="%Y-%m-%dT%H:%M:%SZ",
        input_formats=["%Y-%m-%dT%H:%M:%SZ", "iso-8601"],
        default_timezone=UTC,
    )

    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        coerce_to_string=True,
        min_value=Decimal("0.01"),
    )

    # Optional text fields come back as "" rather than null.
    category = serializers.CharField(allow_blank=True, default="")
    description = serializers.CharField(allow_blank=True, default="")

    class Meta:
        model = Transaction
        fields = [
            "id",
            "account",
            "type",
            "amount",
            "category",
            "description",
            "date",
            "timestamp",
        ]
        read_only_fields = ("timestamp",)

    def validate_account(self, account):
        if account.owner != self.context["request"].user:
            raise serializers.ValidationError("Account not found.")
        return account
