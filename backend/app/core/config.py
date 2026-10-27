import os

from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "60")
)
SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_FROM = os.getenv("SMTP_FROM")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL no está configurada")

if not JWT_SECRET_KEY:
    raise ValueError("JWT_SECRET_KEY no está configurada")


def correo_configurado() -> bool:
    return bool(
        SMTP_HOST
        and SMTP_FROM
        and (bool(SMTP_USERNAME) == bool(SMTP_PASSWORD))
    )