import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class TipoEspacio(enum.Enum):
    FUTBOL = "FUTBOL"
    PADDLE = "PADDLE"
    BASQUET = "BASQUET"
    TENIS = "TENIS"
    VOLEY = "VOLEY"


class EspacioDeportivo(Base):
    __tablename__ = "espacios_deportivos"

    id: Mapped[int] = mapped_column(primary_key=True)

    sede_id: Mapped[int] = mapped_column(
        ForeignKey("sedes.id"),
        nullable=False,
    )

    tipo: Mapped[TipoEspacio] = mapped_column(
        Enum(TipoEspacio),
        nullable=False,
    )

    numero: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    nombre: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )