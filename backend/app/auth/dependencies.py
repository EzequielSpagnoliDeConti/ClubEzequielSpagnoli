
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth
from firebase_admin.exceptions import FirebaseError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.firebase import verificar_token_firebase
from app.db.database import get_db
from app.models.usuario import Usuario


bearer_scheme = HTTPBearer(auto_error=False)


def obtener_payload_firebase(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        bearer_scheme
    ),
) -> dict:

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No estás autenticado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        return verificar_token_firebase(credentials.credentials)

    except (
        auth.InvalidIdTokenError,
        auth.ExpiredIdTokenError,
        auth.RevokedIdTokenError,
        auth.UserDisabledError,
        ValueError,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Firebase inválido o vencido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    except FirebaseError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se pudo verificar la autenticación con Firebase",
        )


def obtener_usuario_actual(
    payload: dict = Depends(obtener_payload_firebase),
    db: Session = Depends(get_db),
) -> Usuario:

    firebase_uid = payload.get("uid")

    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Firebase inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    usuario = db.scalar(
        select(Usuario).where(
            Usuario.firebase_uid == firebase_uid
        )
    )

    if usuario is None or not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no autorizado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return usuario
