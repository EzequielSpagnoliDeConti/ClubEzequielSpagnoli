"""crear tabla de tarifas por deporte

Revision ID: aa716e25c910
Revises: 878665284b4e
Create Date: 2026-10-25 22:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "aa716e25c910"
down_revision: Union[str, Sequence[str], None] = "878665284b4e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "tarifas",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tipo_espacio", sa.String(length=30), nullable=False),
        sa.Column("precio_por_hora", sa.Numeric(10, 2), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.CheckConstraint(
            "precio_por_hora > 0",
            name="ck_tarifas_precio_positivo",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tipo_espacio"),
    )


def downgrade() -> None:
    op.drop_table("tarifas")
