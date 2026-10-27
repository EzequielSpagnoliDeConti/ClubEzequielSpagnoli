from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    user_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        primary_key=True,
    )
    token_hash: Mapped[str] = mapped_column(
        String(64),
        nullable=False,
        unique=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
