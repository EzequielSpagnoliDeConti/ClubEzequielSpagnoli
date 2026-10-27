from datetime import datetime, time

from sqlalchemy import DateTime, String, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Sede(Base):
    __tablename__ = "sedes"

    id: Mapped[int] = mapped_column(primary_key=True)

    nombre: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    direccion: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    hora_apertura: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    hora_cierre: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )