from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Get the project root directory (parent of src/)
PROJECT_ROOT = Path(__file__).parent.parent
ENV_FILE = PROJECT_ROOT / ".env"


class Settings(BaseSettings):
    """Centralna konfiguracja aplikacji z walidacją."""

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Environment
    ENVIRONMENT: Literal["development", "staging", "production"] = Field(
        default="development", description="Środowisko uruchomieniowe"
    )
    DEBUG: bool = Field(default=False, description="Tryb debugowania")

    # Application
    APP_NAME: str = Field(default="FastAPI Starter", description="Nazwa aplikacji")
    APP_VERSION: str = Field(default="1.0.0", description="Wersja aplikacji")

    # Celery
    CELERY_BROKER_URL: str = Field(..., description="URL brokera Celery (RabbitMQ/Redis)")
    CELERY_RESULT_BACKEND: str = Field(
        default=f"db+sqlite:///{PROJECT_ROOT.resolve()}/celery_results.db",
        description="Backend dla wyników Celery (domyślnie SQLite)",
    )

    @field_validator("CELERY_RESULT_BACKEND")
    @classmethod
    def validate_celery_backend(cls, v: str) -> str:
        """Zapewnia, że backend zawsze ma wartość (domyślnie SQLite)."""
        if not v or v.strip() == "":
            db_path = PROJECT_ROOT.resolve() / "celery_results.db"
            return f"db+sqlite:///{db_path}"
        return v

    @field_validator("CELERY_BROKER_URL")
    @classmethod
    def validate_celery_broker(cls, v: str) -> str:
        if not v:
            raise ValueError("CELERY_BROKER_URL jest wymagane")
        return v

    @property
    def is_production(self) -> bool:
        """Sprawdza czy aplikacja działa w produkcji."""
        return self.ENVIRONMENT == "production"

    @property
    def is_development(self) -> bool:
        """Sprawdza czy aplikacja działa w trybie deweloperskim."""
        return self.ENVIRONMENT == "development"


@lru_cache
def get_settings() -> Settings:
    """Singleton dla ustawień.
    Używa lru_cache aby załadować konfigurację tylko raz.
    """
    return Settings()  # type: ignore[call-arg]
