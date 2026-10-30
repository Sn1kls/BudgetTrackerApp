from django.db.models import F
from django.db.models.signals import post_delete, post_save, pre_save
from django.dispatch import receiver

from .models import Account, Transaction


def _delta(tx):
    return tx.amount if tx.type == Transaction.INCOME else -tx.amount


def _apply(account_id, delta):
    Account.objects.filter(pk=account_id).update(balance=F("balance") + delta)


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
        _apply(previous.account_id, -_delta(previous))
    _apply(instance.account_id, _delta(instance))


@receiver(post_delete, sender=Transaction)
def update_balance_on_delete(sender, instance, **kwargs):
    _apply(instance.account_id, -_delta(instance))
