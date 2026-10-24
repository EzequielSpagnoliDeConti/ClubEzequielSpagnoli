from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.espacio_deportivo import TipoEspacio


class EspacioDeportivoDatos(BaseModel):
    sede_id: int = Field(gt=0)
    tipo: TipoEspacio
    numero: int = Field(gt=0)
    nombre: str = Field(min_length=1, max_length=255)


class EspacioDeportivoRespuesta(EspacioDeportivoDatos):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
