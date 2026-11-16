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

## Despliegue en Render y configuración de Firebase

La aplicación utiliza Firebase para la autenticación de usuarios y el envío de notificaciones push. El backend está desarrollado con FastAPI y se despliega en Render, utilizando PostgreSQL como sistema de almacenamiento.

### 1. Configuración de Firebase

El proyecto utiliza los siguientes servicios:

- **Firebase Authentication:** registro, inicio de sesión y recuperación de contraseñas.
- **Firebase Cloud Messaging (FCM):** registro de dispositivos y envío de notificaciones push.

El proyecto de Firebase utilizado es `clubezequielspagnoli-2eeef`.

#### 1.1. Habilitar Firebase Authentication

1. Ingresar a [Firebase Console](https://console.firebase.google.com/).
2. Seleccionar el proyecto `clubezequielspagnoli-2eeef`.
3. Acceder a Authentication.
4. Ingresar en la sección de proveedores de acceso.
5. Habilitar el proveedor **Correo electrónico/Contraseña (Email/Password)**.

#### 1.2. Configurar Firebase en Flutter

Para configurar Firebase en una instalación nueva, es necesario tener instalados Flutter, Node.js y Firebase CLI.

Instalar Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

Instalar FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Desde la carpeta `mobile`, ejecutar:

```bash
flutterfire configure --project=clubezequielspagnoli-2eeef
```

Seleccionar las plataformas que se utilizarán, como Android y Web.

Este procedimiento genera el archivo `lib/firebase_options.dart` y configura los archivos correspondientes a cada plataforma.

Para Android se utiliza también `android/app/google-services.json`.

Instalar las dependencias:

```bash
flutter pub get
```

La inicialización de Firebase está implementada en `mobile/lib/main.dart`, mediante `Firebase.initializeApp()`.

#### 1.3. Configurar Firebase Admin SDK

El backend utiliza Firebase Admin SDK para validar los tokens de autenticación y enviar notificaciones.

Para obtener las credenciales:

1. Ingresar a Firebase Console.
2. Seleccionar el proyecto `clubezequielspagnoli-2eeef`.
3. Acceder a Configuración del proyecto.
4. Abrir la pestaña Cuentas de servicio.
5. Generar una nueva clave privada.
6. Descargar el archivo JSON.

El contenido completo de este archivo deberá configurarse en la variable de entorno `FIREBASE_SERVICE_ACCOUNT_JSON` del backend.

**Importante:** el archivo JSON contiene credenciales privadas. No debe subirse al repositorio ni compartirse públicamente.

### 2. Despliegue del backend en Render

El backend se encuentra dentro de la carpeta `backend` y se despliega como un servicio web de Python.

#### 2.1. Crear la base de datos PostgreSQL

1. Ingresar a [Render](https://render.com/).
2. Crear una nueva instancia de PostgreSQL.
3. Configurar el nombre de la base de datos y el usuario.
4. Obtener la cadena de conexión interna (*Internal Database URL*).

La base de datos deberá estar asociada al servicio web del backend.

#### 2.2. Crear el servicio web

Desde Render:

1. Seleccionar **New → Web Service**.
2. Conectar la cuenta de GitHub.
3. Seleccionar el repositorio `ClubEzequielSpagnoli`.
4. Configurar los siguientes parámetros:

| Parámetro | Valor |
|---|---|
| Name | `club-api` |
| Runtime | Python |
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT` |
| Health Check Path | `/health` |

El comando de inicio ejecuta las migraciones pendientes de Alembic y luego inicia el servidor FastAPI.

#### 2.3. Configurar las variables de entorno

En la sección **Environment** del servicio web, configurar:

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | Cadena de conexión interna de PostgreSQL proporcionada por Render. |
| `JWT_SECRET_KEY` | Clave secreta utilizada por la configuración de seguridad del backend. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Contenido completo del JSON de credenciales de Firebase Admin SDK. |

Para generar una clave segura para `JWT_SECRET_KEY`, se puede ejecutar:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copiar el valor generado y configurarlo en Render.

Las credenciales de Firebase deben cargarse como variable de entorno, conservando la estructura JSON completa.

No se deben almacenar credenciales privadas dentro del repositorio.

#### 2.4. Desplegar el backend

Una vez configuradas las variables:

1. Guardar los cambios.
2. Ejecutar el despliegue del servicio.
3. Revisar los registros de compilación y ejecución.
4. Verificar que las migraciones de Alembic se ejecuten correctamente.
5. Comprobar que el servicio responda.

Direcciones del backend:

- API: `https://club-ezequiel-spagnoli-api.onrender.com`
- Estado del servicio: `https://club-ezequiel-spagnoli-api.onrender.com/health`
- Documentación Swagger: `https://club-ezequiel-spagnoli-api.onrender.com/docs`

### 3. Configuración de Flutter para producción

La dirección del backend se configura en:

`mobile/lib/config/api_config.dart`

Para utilizar el backend desplegado en Render:

```dart
class ApiConfig {
  static const String baseUrl =
      'https://club-ezequiel-spagnoli-api.onrender.com';
}
```

Para trabajar contra un backend local, se puede utilizar:

- Windows: `http://127.0.0.1:8000`
- Emulador Android: `http://10.0.2.2:8000`

Desde la carpeta `mobile`, instalar las dependencias:

```bash
flutter pub get
```

Ejecutar la aplicación:

```bash
flutter run
```

### 4. Notificaciones automáticas de reservas

El backend incorpora un proceso automático que verifica las reservas próximas a comenzar y envía recordatorios mediante Firebase Cloud Messaging.

La lógica se encuentra implementada en:

- `backend/app/notificaciones/recordatorios.py`
- `backend/app/notificaciones/scheduler.py`

El scheduler se inicia junto con FastAPI y realiza una verificación cada minuto.

Cuando detecta una reserva activa cuyo horario de inicio se encuentra dentro de las próximas dos horas, envía una notificación a los dispositivos activos asociados al usuario.

Para que funcione correctamente se requiere:

- Una reserva activa registrada en PostgreSQL.
- Un dispositivo con token FCM registrado y activo.
- Las credenciales de Firebase Admin SDK correctamente configuradas.

**Consideración sobre Render Free:** los servicios gratuitos pueden suspenderse después de un período de inactividad. Mientras el servicio está suspendido, el scheduler no se ejecuta. Cuando el servicio vuelve a iniciarse, el scheduler retoma sus verificaciones.

Por este motivo, esta configuración resulta adecuada para demostraciones y pruebas, pero no garantiza la ejecución continua de los recordatorios.

### 5. Verificación de la instalación

Una vez completada la configuración, se recomienda comprobar:

1. **Backend:** acceder a `/health` y verificar que responda `{"status":"ok"}`.
2. **Base de datos:** comprobar que las migraciones se hayan aplicado correctamente.
3. **Firebase Authentication:** realizar un registro y un inicio de sesión.
4. **Perfil de usuario:** comprobar que el backend pueda recuperar los datos del usuario autenticado.
5. **FCM:** iniciar sesión y verificar que el dispositivo quede registrado en `dispositivos_fcm`.
6. **Notificaciones:** realizar una prueba de envío y comprobar que el dispositivo reciba el mensaje.
7. **Reservas:** crear una reserva y verificar el envío automático del recordatorio cuando corresponda.

Con estos pasos, el backend y la aplicación Flutter quedan configurados para trabajar con Firebase y Render.