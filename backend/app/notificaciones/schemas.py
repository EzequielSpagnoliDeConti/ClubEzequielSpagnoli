
from pydantic import BaseModel, Field


class DispositivoFCMRequest(BaseModel):
    token: str = Field(min_length=1, max_length=512)


class DispositivoFCMRespuesta(BaseModel):
    mensaje: str


class NotificacionPruebaRequest(BaseModel):
    titulo: str = Field(min_length=1, max_length=100)
    cuerpo: str = Field(min_length=1, max_length=500)


class NotificacionPruebaRespuesta(BaseModel):
    mensaje: str
    enviados: int
    fallidos: int