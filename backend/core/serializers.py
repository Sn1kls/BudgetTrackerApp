from django.contrib.auth.models import User
from rest_framework import serializers
from datetime import timezone
from decimal import Decimal

from .models import Account, Transaction


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ["username", "email", "password"]

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class AccountSerializer(serializers.ModelSerializer):
    # balance — завжди рядок з двома знаками
    balance = serializers.DecimalField(
        max_digits=12, decimal_places=2, coerce_to_string=True
    )

    class Meta:
        model = Account
        fields = ["id", "name", "balance", "owner"]
        read_only_fields = ("owner",)


class TransactionSerializer(serializers.ModelSerializer):
    # date — завжди ISO-8601 UTC з “Z” у кінці
    date = serializers.DateTimeField(
        format="%Y-%m-%dT%H:%M:%SZ",
        input_formats=["%Y-%m-%dT%H:%M:%SZ", "iso-8601"],
        default_timezone=timezone.utc,
    )

    # amount — завжди рядок
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        coerce_to_string=True,
        min_value=Decimal("0.01"),
    )

    # optional поля — не null, а порожній рядок
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
