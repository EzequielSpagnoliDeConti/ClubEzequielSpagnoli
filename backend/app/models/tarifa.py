from datetime import datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, DateTime, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Tarifa(Base):
    __tablename__ = "tarifas"
    __table_args__ = (
        CheckConstraint("precio_por_hora > 0", name="ck_tarifas_precio_positivo"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    tipo_espacio: Mapped[str] = mapped_column(
        String(30),
        unique=True,
        nullable=False,
    )
    precio_por_hora: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
