from django.db.models import F
from django.db.models.signals import post_delete, post_save, pre_save
from django.dispatch import receiver

from .models import Account, Transaction


def balance_change(transaction):
    return (
        transaction.amount
        if transaction.type == Transaction.INCOME
        else -transaction.amount
    )


def add_to_balance(account_id, amount):
    Account.objects.filter(pk=account_id).update(balance=F("balance") + amount)


@receiver(pre_save, sender=Transaction)
def remember_previous_version(sender, instance, **kwargs):
    instance._previous = (
        Transaction.objects.filter(pk=instance.pk).first() if instance.pk else None
    )


@receiver(post_save, sender=Transaction)
def update_balance_on_save(sender, instance, **kwargs):
    # Undo the old version, then apply the new one.
    previous = getattr(instance, "_previous", None)
    if previous:
        add_to_balance(previous.account_id, -balance_change(previous))
    add_to_balance(instance.account_id, balance_change(instance))


@receiver(post_delete, sender=Transaction)
def update_balance_on_delete(sender, instance, **kwargs):
    add_to_balance(instance.account_id, -balance_change(instance))
