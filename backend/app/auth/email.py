import logging
import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import (
    SMTP_FROM,
    SMTP_HOST,
    SMTP_PASSWORD,
    SMTP_PORT,
    SMTP_USERNAME,
    correo_configurado,
)


logger = logging.getLogger(__name__)


def enviar_codigo_restauracion(destinatario: str, token: str) -> None:
    if not correo_configurado() or SMTP_HOST is None or SMTP_FROM is None:
        raise RuntimeError("El servicio SMTP no está configurado.")

    mensaje = EmailMessage()
    mensaje["Subject"] = "Restablecimiento de contraseña"
    mensaje["From"] = SMTP_FROM
    mensaje["To"] = destinatario
    mensaje.set_content(
        "Recibimos una solicitud para restablecer la contraseña de tu cuenta "
        "del Club Ezequiel Spagnoli.\n\n"
        f"Copiá este código en la aplicación:\n{token}\n\n"
        "El código vence en 30 minutos y solo puede usarse una vez. "
        "Si no solicitaste este cambio, ignorá este correo."
    )

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10) as servidor:
            servidor.starttls(context=ssl.create_default_context())
            if SMTP_USERNAME and SMTP_PASSWORD:
                servidor.login(SMTP_USERNAME, SMTP_PASSWORD)
            servidor.send_message(mensaje)
    except (OSError, smtplib.SMTPException):
        logger.exception("No se pudo enviar un correo de restablecimiento.")
