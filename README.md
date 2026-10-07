# ClubEzequielSpagnoli - Backend

API REST para la gestión de espacios deportivos.

## Tecnologías

- Python
- FastAPI
- SQLAlchemy
- Alembic
- PostgreSQL
- Docker

## Ejecutar localmente desde la carpeta raiz

Crear entorno virtual:

```bash
python -m venv .venv
```

Instalar dependencias:

```bash
.venv/Scripts/activate
pip install -r /backend/requirements.txt
```

Levantar PostgreSQL:

```bash
docker compose up -d
```

Ejecutar migraciones:
```bash
alembic upgrade head
```

Iniciar API
```bash
uvicorn app.main:app --reload
```