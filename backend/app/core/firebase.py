import json

import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import FIREBASE_SERVICE_ACCOUNT_JSON


def obtener_app_firebase():
    """Inicializa Firebase Admin una sola vez."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass

    if not FIREBASE_SERVICE_ACCOUNT_JSON:
        raise RuntimeError(
            "FIREBASE_SERVICE_ACCOUNT_JSON no está configurada."
        )

    try:
        credenciales = json.loads(FIREBASE_SERVICE_ACCOUNT_JSON)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            "FIREBASE_SERVICE_ACCOUNT_JSON no contiene un JSON válido."
        ) from exc

    certificado = credentials.Certificate(credenciales)

    return firebase_admin.initialize_app(certificado)


def verificar_token_firebase(id_token: str) -> dict:
    """Verifica el ID Token y devuelve los datos decodificados."""
    app = obtener_app_firebase()

    return auth.verify_id_token(
        id_token,
        app=app,
        check_revoked=True,
    )
