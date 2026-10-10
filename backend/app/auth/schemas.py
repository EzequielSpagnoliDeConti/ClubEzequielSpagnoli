from datetime import date

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegistroUsuario(BaseModel):
    nombre: str = Field(min_length=1, max_length=100)
    apellido: str = Field(min_length=1, max_length=100)
    dni: str = Field(min_length=1, max_length=20)
    fecha_nacimiento: date
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class RegistroRespuesta(BaseModel):
    mensaje: str
    email: EmailStr


class LoginUsuario(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)


class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UsuarioActualRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    apellido: str
    email: EmailStr