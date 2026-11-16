# ClubEzequielSpagnoli

Aplicación para la gestión de espacios deportivos. El repositorio contiene una API REST en FastAPI y una aplicación cliente en Flutter.

## Requisitos

- Python 3 y `pip`
- Docker Desktop con Docker Compose
- Flutter SDK y Dart
- Un navegador compatible o un emulador/dispositivo para ejecutar Flutter

## Configuración y ejecución local

### 1. Iniciar PostgreSQL

Desde la raíz del repositorio, iniciar la base de datos definida en `docker-compose.yml`:

```bash
docker compose up -d
```

### 2. Configurar y ejecutar el backend

Desde la raíz, crear y activar un entorno virtual e instalar las dependencias:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r backend\requirements.txt
```

Si PowerShell no permite activar el entorno virtual, se puede usar `.\.venv\Scripts\activate.bat` desde `cmd`.

Crear `backend/.env` a partir de `backend/.env_example` y configurar al menos estas variables:

```dotenv
DATABASE_URL=postgresql+psycopg://usuario:contraseña@localhost:5432/club
JWT_SECRET_KEY=una-clave-secreta-local
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60
```

SMTP puede quedar sin configurar si no se prueban las funciones de correo. Las funciones que verifican tokens de Firebase en el backend también requieren `FIREBASE_SERVICE_ACCOUNT_JSON`, con las credenciales de una cuenta de servicio del proyecto Firebase en formato JSON. No publiques ni compartas ese archivo o sus credenciales.

En una terminal ubicada dentro de `backend`, ejecutar las migraciones e iniciar la API:

```bash
cd backend
alembic upgrade head
uvicorn app.main:app --reload
```

Mantener esa terminal abierta mientras se usa la app. La API queda disponible en `http://127.0.0.1:8000`; la documentación interactiva está en `http://127.0.0.1:8000/docs` y el estado de salud en `http://127.0.0.1:8000/health`.

### 3. Configurar y ejecutar Flutter

Antes de ejecutar Flutter, cambiar `ApiConfig.baseUrl` en `mobile/lib/config/api_config.dart` para apuntar a la API local:

- Flutter Web en la misma computadora: `http://127.0.0.1:8000`
- Emulador Android: `http://10.0.2.2:8000`
- Dispositivo físico: `http://<IP-local-de-la-computadora>:8000`; para este caso, iniciar Uvicorn con `uvicorn app.main:app --reload --host 0.0.0.0` y asegurar que ambos dispositivos estén en la misma red.

En una segunda terminal, desde la raíz del repositorio, instalar las dependencias y ejecutar la app:

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=5000
```

El backend permite solicitudes web desde `localhost:5000` y `127.0.0.1:5000`. Para otro destino, consultar los dispositivos disponibles con `flutter devices` y ejecutar `flutter run -d <id-del-dispositivo>`.

La app inicializa Firebase al arrancar. La configuración de plataformas está en `mobile/lib/firebase_options.dart`; para usar Firebase Auth y notificaciones, el proyecto Firebase debe estar habilitado y configurado para la plataforma de destino.

## Detener los servicios

Para detener PostgreSQL sin eliminar sus datos:

```bash
docker compose down
```
