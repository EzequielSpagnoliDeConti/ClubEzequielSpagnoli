from datetime import date, datetime, time

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.reserva import EstadoReserva


class ReservaDatos(BaseModel):
    usuario_id: int = Field(gt=0)
    espacio_deportivo_id: int = Field(gt=0)
    fecha: date
    hora_inicio: time
    hora_fin: time

    @model_validator(mode="after")
    def validar_horario(self):
        if self.hora_inicio >= self.hora_fin:
            raise ValueError("La hora de inicio debe ser anterior a la hora de fin.")
        return self


class ReservaRespuesta(ReservaDatos):
    model_config = ConfigDict(from_attributes=True)

    id: int
    estado: EstadoReserva
    created_at: datetime
    updated_at: datetime
    cancelada_at: datetime | None
