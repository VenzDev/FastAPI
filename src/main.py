from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from src.tasks import process_message

app = FastAPI(title="FastAPI Starter", description="A starter FastAPI application", version="1.0.0")

# CORS middleware
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
