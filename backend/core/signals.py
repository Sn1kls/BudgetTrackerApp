from django.db.models.signals import pre_save, post_save, post_delete
from django.dispatch import receiver
from django.db import models
from .models import Transaction, Account


@receiver(pre_save, sender=Transaction)
def cache_old_transaction(sender, instance, **kwargs):
    """
    Перед тим, як зберегти оновлений Transaction,
    тягнемо з БД його попередню версію і підклеюємо
    у атрибут _old_instance
    """
    if instance.pk:
        try:
            instance._old_instance = Transaction.objects.get(pk=instance.pk)
        except Transaction.DoesNotExist:
            instance._old_instance = None
    else:
        instance._old_instance = None


@receiver(post_save, sender=Transaction)
def adjust_balance_on_create_or_update(sender, instance, created, **kwargs):
    """
    Якщо created=True — це нова транзакція, стандартно додаємо або віднімаємо.
    Якщо created=False — це апдейт, рахуємо різницю між новим і старим delta
    і саме її застосовуємо до рахунку.
    """
    from django.db.models import F

    def delta_for(tx):
        return tx.amount if tx.type == Transaction.INCOME else -tx.amount

    if created:
        delta = delta_for(instance)
    else:
        old = getattr(instance, "_old_instance", None)
        if old:
            new_delta = delta_for(instance)
            old_delta = delta_for(old)
            delta = new_delta - old_delta
        else:
            # якщо з якихось причин не вдалось взяти old, fallback на новий дельта
            delta = delta_for(instance)

    # Оновлюємо balance одним F-виразом
    Account.objects.filter(pk=instance.account_id).update(balance=F("balance") + delta)


@receiver(post_delete, sender=Transaction)
def adjust_balance_on_delete(sender, instance, **kwargs):
    """
    При видаленні беремо протилежний дельта, щоб «відкотити» запис.
    """
    from django.db.models import F

    delta = -instance.amount if instance.type == Transaction.INCOME else instance.amount
    Account.objects.filter(pk=instance.account_id).update(balance=F("balance") + delta)
