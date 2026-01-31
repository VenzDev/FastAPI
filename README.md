# FastAPI Starter Project

Projekt startowy FastAPI z Docker Compose.

## Wymagania

- Docker
- Docker Compose
- Make (opcjonalnie, ale zalecane)

## Uruchomienie

### Szybki start

```bash
make up-build
```

Aplikacja będzie dostępna pod adresem: **http://localhost:8000**

### Dostępne komendy

Użyj `make help` aby zobaczyć wszystkie dostępne komendy:

- `make up` - Uruchom aplikację w tle
- `make up-build` - Zbuduj i uruchom aplikację
- `make down` - Zatrzymaj aplikację
- `make logs` - Pokaż logi aplikacji
- `make restart` - Zrestartuj aplikację

### Bez Makefile

Jeśli nie masz Make, możesz użyć bezpośrednio Docker Compose:

```bash
cd docker && docker-compose up --build -d
```

## Endpointy

- `GET /` - Główny endpoint zwracający wiadomość powitalną
- `GET /health` - Endpoint sprawdzający status aplikacji
- `GET /docs` - Automatyczna dokumentacja Swagger UI
- `GET /redoc` - Alternatywna dokumentacja ReDoc

## Rozwój

Pliki są montowane jako volume, więc zmiany w kodzie będą automatycznie widoczne dzięki `--reload` w uvicorn.

## Więcej informacji

- **Wdrożenie na AWS ECS**: Zobacz [terraform/README.md](terraform/README.md)
- **CI/CD z GitHub Actions**: Zobacz [.github/workflows/README.md](.github/workflows/README.md)
