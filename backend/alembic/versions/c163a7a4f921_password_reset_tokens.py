"""Agregar restablecimiento seguro de contraseña

Revision ID: c163a7a4f921
Revises: aa716e25c910
Create Date: 2026-10-26 22:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c163a7a4f921"
down_revision: Union[str, Sequence[str], None] = "aa716e25c910"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "usuarios",
        sa.Column(
            "token_version",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.create_table(
        "password_reset_tokens",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "expires_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["usuarios.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("user_id"),
        sa.UniqueConstraint("token_hash"),
    )


def downgrade() -> None:
    op.drop_table("password_reset_tokens")
    op.drop_column("usuarios", "token_version")
