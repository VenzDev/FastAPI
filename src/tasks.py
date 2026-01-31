from datetime import datetime

from src.celery_app import celery_app


@celery_app.task(name="tasks.process_message")
def process_message(message: str) -> dict:
    """
    Przykładowe zadanie Celery, które przetwarza wiadomość.
    W rzeczywistej aplikacji tutaj można wykonać ciężkie operacje.
    """
    # Symulacja przetwarzania
    result = {
        "status": "processed",
        "message": message,
        "processed_at": datetime.utcnow().isoformat() + "Z",
    }
    return result
