"""Componer el nombre de los espacios con los datos de su sede

Revision ID: d892bf874251
Revises: c163a7a4f921
Create Date: 2026-10-26 22:55:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from app.espacios_deportivos.naming import generar_nombre_espacio
from app.models.espacio_deportivo import TipoEspacio


revision: str = "d892bf874251"
down_revision: Union[str, Sequence[str], None] = "c163a7a4f921"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    espacios = sa.table(
        "espacios_deportivos",
        sa.column("id", sa.Integer()),
        sa.column("sede_id", sa.Integer()),
        sa.column("tipo", sa.String()),
        sa.column("numero", sa.Integer()),
        sa.column("nombre", sa.String()),
    )
    sedes = sa.table(
        "sedes",
        sa.column("id", sa.Integer()),
        sa.column("nombre", sa.String()),
        sa.column("direccion", sa.String()),
    )

    filas = bind.execute(
        sa.select(
            espacios.c.id,
            espacios.c.tipo,
            espacios.c.numero,
            sedes.c.nombre,
            sedes.c.direccion,
        ).join(sedes, espacios.c.sede_id == sedes.c.id)
    ).all()

    for fila in filas:
        bind.execute(
            espacios.update()
            .where(espacios.c.id == fila.id)
            .values(
                nombre=generar_nombre_espacio(
                    fila.nombre,
                    fila.direccion,
                    TipoEspacio[fila.tipo],
                    fila.numero,
                )
            )
        )


def downgrade() -> None:
    pass
