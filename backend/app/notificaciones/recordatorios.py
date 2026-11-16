
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import SessionLocal
from app.models.reserva import EstadoReserva, Reserva
from app.models.dispositivo_fcm import DispositivoFCM
from app.notificaciones.service import enviar_notificacion


logger = logging.getLogger(__name__)

ZONA_HORARIA = ZoneInfo("America/Argentina/Buenos_Aires")


def procesar_recordatorios() -> dict:
    """
    Busca reservas que comienzan dentro de las próximas dos horas
    y envía sus recordatorios a los dispositivos activos.
    """

    ahora = datetime.now(ZONA_HORARIA).replace(tzinfo=None)
    hasta = ahora + timedelta(hours=2)

    db: Session = SessionLocal()

    procesadas = 0
    enviadas = 0
    fallidas = 0
    sin_dispositivos = 0

    try:
        reservas = db.scalars(
            select(Reserva).where(
                Reserva.estado == EstadoReserva.ACTIVA,
                Reserva.recordatorio_enviado_at.is_(None),
                Reserva.fecha >= ahora.date(),
            )
        ).all()

        for reserva in reservas:
            inicio_reserva = datetime.combine(
                reserva.fecha,
                reserva.hora_inicio,
            )

            # Solo reservas que todavía no comenzaron
            # y cuyo inicio está dentro de las próximas dos horas.
            if not (ahora < inicio_reserva <= hasta):
                continue

            procesadas += 1

            dispositivos = db.scalars(
                select(DispositivoFCM).where(
                    DispositivoFCM.usuario_id == reserva.usuario_id,
                    DispositivoFCM.activo.is_(True),
                )
            ).all()

            if not dispositivos:
                sin_dispositivos += 1
                continue

            exitosos = 0

            for dispositivo in dispositivos:
                try:
                    enviar_notificacion(
                        dispositivo=dispositivo,
                        titulo="¡Tu reserva se acerca!",
                        cuerpo=(
                            "Tu reserva deportiva comienza dentro "
                            "de las próximas 2 horas."
                        ),
                    )
                    exitosos += 1

                except Exception:
                    logger.exception(
                        "Error enviando recordatorio de reserva %s "
                        "al dispositivo %s",
                        reserva.id,
                        dispositivo.id,
                    )
                    fallidas += 1

            # Marcamos el recordatorio si al menos un dispositivo
            # recibió correctamente el mensaje.
            if exitosos > 0:
                reserva.recordatorio_enviado_at = ahora
                db.commit()
                enviadas += 1

        return {
            "reservas_procesadas": procesadas,
            "reservas_con_recordatorio_enviado": enviadas,
            "dispositivos_fallidos": fallidas,
            "reservas_sin_dispositivos": sin_dispositivos,
        }

    except Exception:
        db.rollback()
        logger.exception("Error procesando recordatorios de reservas")
        raise

    finally:
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    resultado = procesar_recordatorios()

    logger.info("Resultado del proceso: %s", resultado)
