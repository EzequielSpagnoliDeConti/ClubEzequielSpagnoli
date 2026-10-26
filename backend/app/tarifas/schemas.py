from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.espacio_deportivo import TipoEspacio


class TarifaRespuesta(BaseModel):
    id: int
    tipo_espacio: TipoEspacio
    precio_por_hora: Decimal = Field(gt=0)
    updated_at: datetime
