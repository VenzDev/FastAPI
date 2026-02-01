from celery.result import AsyncResult  # type: ignore[import-untyped]
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from src.celery_app import celery_app
from src.config import get_settings
from src.tasks import process_message

settings = get_settings()

app = FastAPI(
    title=settings.APP_NAME,
    description="A starter FastAPI application",
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MessageRequest(BaseModel):
    message: str


@app.get("/")
async def root():
    return {"message": "Hello World", "status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/send-task")
async def send_task(request: MessageRequest):
    """
    Endpoint do wysyłania zadań do kolejki RabbitMQ przez Celery.
    """
    try:
        task = process_message.delay(request.message)
        return {
            "status": "success",
            "message": "Task sent to queue",
            "task_id": task.id,
            "message_content": request.message,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send task: {str(e)}") from e


@app.get("/task/{task_id}")
async def get_task_status(task_id: str):
    """
    Endpoint do sprawdzania statusu i wyniku zadania Celery.
    """
    try:
        task_result = AsyncResult(task_id, app=celery_app)
        response = {
            "task_id": task_id,
            "status": task_result.state,
        }

        if task_result.state == "PENDING":
            response["message"] = "Task is waiting to be processed"
        elif task_result.state == "PROGRESS":
            response["current"] = task_result.info.get("current", 0)
            response["total"] = task_result.info.get("total", 0)
        elif task_result.state == "SUCCESS":
            response["result"] = task_result.result
        elif task_result.state == "FAILURE":
            response["error"] = str(task_result.info)

        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get task status: {str(e)}") from e
