from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session
import logging

from app.db.database import get_db
from app.auth.dependencies import obtener_usuario_actual
from app.models.usuario import Usuario
from app.models.dispositivo_fcm import DispositivoFCM
from app.notificaciones.schemas import (
    DispositivoFCMRequest,
    DispositivoFCMRespuesta,
    NotificacionPruebaRequest,
    NotificacionPruebaRespuesta,
)
from app.notificaciones.service import enviar_notificacion



router = APIRouter(
    prefix="/notificaciones",
    tags=["Notificaciones"],
)

logger = logging.getLogger(__name__)

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

@router.post(
    "/probar",
    response_model=NotificacionPruebaRespuesta,
)
def probar_notificacion(
    datos: NotificacionPruebaRequest,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(obtener_usuario_actual),
):
    dispositivos = db.scalars(
        select(DispositivoFCM).where(
            DispositivoFCM.usuario_id == usuario.id,
            DispositivoFCM.activo.is_(True),
        )
    ).all()

    enviados = 0
    fallidos = 0

    for dispositivo in dispositivos:
        try:
            enviar_notificacion(
                dispositivo=dispositivo,
                titulo=datos.titulo,
                cuerpo=datos.cuerpo,
            )
            enviados += 1
        except Exception:
            logger.exception(
                "Error al enviar notificación al dispositivo %s",
                dispositivo.id,
            )
            fallidos += 1
    return {
        "mensaje": "Proceso de envío finalizado.",
        "enviados": enviados,
        "fallidos": fallidos,
    }
