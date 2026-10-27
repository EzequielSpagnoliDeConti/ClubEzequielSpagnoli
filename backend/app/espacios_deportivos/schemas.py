from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.espacio_deportivo import TipoEspacio


class EspacioDeportivoDatos(BaseModel):
    sede_id: int = Field(gt=0)
    tipo: TipoEspacio
    numero: int = Field(gt=0)


class EspacioDeportivoRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sede_id: int
    tipo: TipoEspacio
    numero: int
    nombre: str
    created_at: datetime
