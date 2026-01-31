.PHONY: help up up-build down restart logs status clean shell install install-docker sync-deps

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
	@echo "  make install-docker - Przebuduj Docker z nowymi zależnościami"
	@echo "  make sync-deps     - Zsynchronizuj zależności (venv + Docker)"

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

# Przebuduj Docker z nowymi zależnościami
install-docker: down
	cd docker && docker-compose build --no-cache
	cd docker && docker-compose up -d
	@echo "✓ Docker przebudowany z nowymi zależnościami"

# Zsynchronizuj zależności w obu środowiskach
sync-deps: install install-docker
	@echo "✓ Zależności zsynchronizowane w .venv i Dockerze"
