
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.dependencies import obtener_usuario_actual
from app.models.usuario import Usuario
from app.models.dispositivo_fcm import DispositivoFCM
from app.notificaciones.schemas import (
    DispositivoFCMRequest,
    DispositivoFCMRespuesta,
)


router = APIRouter(
    prefix="/notificaciones",
    tags=["Notificaciones"],
)


@router.post(
    "/dispositivos",
    response_model=DispositivoFCMRespuesta,
)
def registrar_dispositivo(
    datos: DispositivoFCMRequest,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
):
    ahora = datetime.now()

    dispositivo = db.scalar(
        select(DispositivoFCM).where(
            DispositivoFCM.token == datos.token
        )
    )

    if dispositivo:
        # Si el token ya existe, lo asociamos al usuario actual.
        dispositivo.usuario_id = usuario.id
        dispositivo.activo = True
        dispositivo.updated_at = ahora
    else:
        dispositivo = DispositivoFCM(
            usuario_id=usuario.id,
            token=datos.token,
            activo=True,
            created_at=ahora,
            updated_at=ahora,
        )

        db.add(dispositivo)

    db.commit()

    return {
        "mensaje": "Dispositivo registrado correctamente."
    }


@router.post(
    "/dispositivos/desactivar",
    response_model=DispositivoFCMRespuesta,
)
def desactivar_dispositivo(
    datos: DispositivoFCMRequest,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
):
    dispositivo = db.scalar(
        select(DispositivoFCM).where(
            DispositivoFCM.token == datos.token,
            DispositivoFCM.usuario_id == usuario.id,
        )
    )

    if dispositivo:
        dispositivo.activo = False
        dispositivo.updated_at = datetime.now()
        db.commit()

    return {
        "mensaje": "Dispositivo desactivado correctamente."
    }
