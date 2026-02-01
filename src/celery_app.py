from celery import Celery  # type: ignore[import-untyped]

from src.config import get_settings

settings = get_settings()

# Create Celery instance
celery_app = Celery(
    "fastapi_app",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["src.tasks"],
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,
    task_soft_time_limit=25 * 60,
    result_backend=settings.CELERY_RESULT_BACKEND,
)
