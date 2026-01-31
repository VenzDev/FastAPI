import os

from celery import Celery

# RabbitMQ connection URL
broker_url = os.getenv("CELERY_BROKER_URL")
# RPC backend for results (uses RabbitMQ RPC, no additional service needed)
result_backend = os.getenv("CELERY_RESULT_BACKEND")

# Create Celery instance
celery_app = Celery(
    "fastapi_app",
    broker=broker_url,
    backend=result_backend,
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
)
