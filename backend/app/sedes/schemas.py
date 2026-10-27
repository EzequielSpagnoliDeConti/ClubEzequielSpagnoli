from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, Field, model_validator


class SedeDatos(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    direccion: str = Field(min_length=1, max_length=255)
    hora_apertura: time
    hora_cierre: time

    @model_validator(mode="after")
    def validar_horario(self):
        if self.hora_apertura >= self.hora_cierre:
            raise ValueError("La hora de apertura debe ser anterior al cierre.")
        return self


class SedeRespuesta(SedeDatos):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
