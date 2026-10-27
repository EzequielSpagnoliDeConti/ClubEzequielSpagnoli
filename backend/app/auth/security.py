from datetime import datetime, timedelta, timezone

import jwt

from app.core.config import (
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES,
    JWT_ALGORITHM,
    JWT_SECRET_KEY,
)


def crear_access_token(user_id: int, token_version: int = 0) -> str:
    ahora = datetime.now(timezone.utc)

    payload = {
        "sub": str(user_id),
        "ver": token_version,
        "iat": ahora,
        "exp": ahora + timedelta(
            minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES
        ),
    }

    return jwt.encode(
        payload,
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM,
    )