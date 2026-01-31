.PHONY: help up up-build down restart logs status clean shell install install-dev install-docker sync-deps lint format type-check test security-check quality-check ensure-container-running

# Default target
help:
	@echo "Dostępne komendy:"
	@echo "  make up            - Uruchom aplikację w tle"
	@echo "  make up-build      - Zbuduj i uruchom aplikację"
	@echo "  make down          - Zatrzymaj aplikację"
	@echo "  make restart       - Zrestartuj aplikację"
	@echo "  make logs          - Pokaż logi aplikacji"
	@echo "  make status        - Sprawdź status kontenerów"
	@echo "  make clean         - Zatrzymaj i usuń kontenery"
	@echo "  make shell         - Otwórz shell w kontenerze"
	@echo ""
	@echo "Zarządzanie zależnościami:"
	@echo "  make install       - Zainstaluj zależności w środowisku wirtualnym (.venv)"
	@echo "  make install-dev   - Zainstaluj zależności deweloperskie (wymagane dla quality-check)"
	@echo "  make install-docker - Przebuduj Docker z nowymi zależnościami"
	@echo "  make sync-deps     - Zsynchronizuj zależności (venv + Docker)"
	@echo ""
	@echo "Jakość kodu (w kontenerze Docker):"
	@echo "  make lint          - Uruchom linter (ruff)"
	@echo "  make format        - Sformatuj kod (ruff)"
	@echo "  make type-check    - Sprawdź typy (mypy)"
	@echo "  make test          - Uruchom testy (pytest)"
	@echo "  make security-check - Sprawdź bezpieczeństwo (bandit)"
	@echo "  make quality-check - Uruchom wszystkie sprawdzenia jakości"

# Uruchom aplikację w tle
up:
	cd docker && docker-compose up -d

# Zbuduj i uruchom aplikację
up-build:
	cd docker && docker-compose up --build -d

# Zatrzymaj aplikację
down:
	cd docker && docker-compose down

# Zrestartuj aplikację
restart: down up

# Pokaż logi aplikacji
logs:
	cd docker && docker-compose logs -f

# Sprawdź status kontenerów
status:
	cd docker && docker-compose ps

# Zatrzymaj i usuń kontenery
clean: down
	cd docker && docker-compose rm -f

# Otwórz shell w kontenerze
shell:
	cd docker && docker-compose exec api /bin/bash

# Zainstaluj zależności w środowisku wirtualnym (dla IDE)
install:
	@if [ ! -d ".venv" ]; then \
		echo "Tworzenie środowiska wirtualnego..."; \
		python3 -m venv .venv; \
	fi
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements.txt
	@echo "✓ Zależności zainstalowane w .venv"

# Zainstaluj zależności deweloperskie (wymagane dla quality-check)
install-dev:
	@if [ ! -d ".venv" ]; then \
		echo "Tworzenie środowiska wirtualnego..."; \
		python3 -m venv .venv; \
	fi
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements-dev.txt
	@echo "✓ Zależności deweloperskie zainstalowane w .venv"

# Przebuduj Docker z nowymi zależnościami (deweloperski - z dev dependencies)
install-docker: down
	cd docker && docker-compose build --no-cache
	cd docker && docker-compose up -d
	@echo "✓ Docker deweloperski przebudowany z nowymi zależnościami (włącznie z dev)"

# Zsynchronizuj zależności w obu środowiskach
sync-deps: install install-docker
	@echo "✓ Zależności zsynchronizowane w .venv i Dockerze"

# Code quality commands (uruchamiane w kontenerze Docker)
# Sprawdź czy kontener jest uruchomiony
.PHONY: ensure-container-running
ensure-container-running:
	@cd docker && docker-compose ps api | grep -q "Up" || (echo "⚠️  Kontener nie jest uruchomiony. Uruchamianie..." && $(MAKE) up)

lint: ensure-container-running
	@echo "🔍 Uruchamianie lintera (ruff) w kontenerze..."
	cd docker && docker-compose exec -T api ruff check .

format: ensure-container-running
	@echo "✨ Formatowanie kodu (ruff) w kontenerze..."
	cd docker && docker-compose exec -T api ruff format .

type-check: ensure-container-running
	@echo "🔎 Sprawdzanie typów (mypy) w kontenerze..."
	cd docker && docker-compose exec -T api mypy . || true

test: ensure-container-running
	@echo "🧪 Uruchamianie testów (pytest) w kontenerze..."
	cd docker && docker-compose exec -T api pytest --cov=. --cov-report=term-missing

security-check: ensure-container-running
	@echo "🔒 Sprawdzanie bezpieczeństwa (bandit) w kontenerze..."
	cd docker && docker-compose exec -T api sh -c "bandit -r . -f json -o bandit-report.json || true"
	cd docker && docker-compose exec -T api bandit -r .

quality-check: lint type-check test
	@echo "✅ Wszystkie sprawdzenia jakości zakończone"
