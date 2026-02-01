import logging
from datetime import datetime

from src.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="tasks.process_message")
def process_message(message: str) -> dict:
    """
    Przykładowe zadanie Celery, które przetwarza wiadomość.
    W rzeczywistej aplikacji tutaj można wykonać ciężkie operacje.
    """
    logger.info(f"Rozpoczynam przetwarzanie wiadomości: {message}")

    result = {
        "status": "processed",
        "message": message,
        "processed_at": datetime.utcnow().isoformat() + "Z",
    }

    logger.info(f"Zakończono przetwarzanie wiadomości: {message}")
    return result
