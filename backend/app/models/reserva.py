import enum
from datetime import date, datetime, time

from sqlalchemy import (
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Time,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class EstadoReserva(enum.Enum):
    ACTIVA = "ACTIVA"
    CANCELADA = "CANCELADA"
    FINALIZADA = "FINALIZADA"


class Reserva(Base):
    __tablename__ = "reservas"

    id: Mapped[int] = mapped_column(primary_key=True)

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"),
        nullable=False,
    )

    espacio_deportivo_id: Mapped[int] = mapped_column(
        ForeignKey("espacios_deportivos.id"),
        nullable=False,
    )

    fecha: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    hora_inicio: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    hora_fin: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    estado: Mapped[EstadoReserva] = mapped_column(
        Enum(EstadoReserva),
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )

    cancelada_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )