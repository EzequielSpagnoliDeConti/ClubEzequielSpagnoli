
from pydantic import BaseModel, Field


class DispositivoFCMRequest(BaseModel):
    token: str = Field(min_length=1, max_length=512)


class DispositivoFCMRespuesta(BaseModel):
    mensaje: str
