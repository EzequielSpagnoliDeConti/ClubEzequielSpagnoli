
import logging
from zoneinfo import ZoneInfo

from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.notificaciones.recordatorios import procesar_recordatorios

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)

ZONA_HORARIA = ZoneInfo("America/Argentina/Buenos_Aires")

scheduler = AsyncIOScheduler(timezone=ZONA_HORARIA)


def ejecutar_recordatorios():
    logger.info("Ejecutando proceso automático de recordatorios.")

    try:
        resultado = procesar_recordatorios()
        logger.info("Resultado de recordatorios: %s", resultado)
    except Exception:
        logger.exception("Error al procesar los recordatorios.")


def iniciar_scheduler():
    if scheduler.running:
        logger.warning("El scheduler ya estaba iniciado.")
        return

    scheduler.add_job(
        ejecutar_recordatorios,
        trigger="interval",
        minutes=1,
        id="recordatorios_reservas",
        name="Envío de recordatorios de reservas",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
        misfire_grace_time=60,
    )

    scheduler.start()
    logger.info("Scheduler iniciado. Recordatorios cada minuto.")


def detener_scheduler():
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Scheduler detenido.")
