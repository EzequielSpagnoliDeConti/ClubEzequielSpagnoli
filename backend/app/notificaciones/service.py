from firebase_admin import messaging

from app.core.firebase import obtener_app_firebase
from app.models.dispositivo_fcm import DispositivoFCM


def enviar_notificacion(
    dispositivo: DispositivoFCM,
    titulo: str,
    cuerpo: str,
) -> None:
    """Envía una notificación push a un dispositivo específico."""

    app = obtener_app_firebase()

    mensaje = messaging.Message(
        notification=messaging.Notification(
            title=titulo,
            body=cuerpo,
        ),
        token=dispositivo.token,
    )

    messaging.send(mensaje, app=app)