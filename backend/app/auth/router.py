from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pwdlib import PasswordHash
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.usuario import Usuario
from app.auth.schemas import (
    ActualizarPerfilUsuario,
    LoginUsuario,
    RegistroRespuesta,
    RegistroUsuario,
    TokenRespuesta,
    UsuarioActualRespuesta,
)
from app.auth.security import crear_access_token
from app.auth.dependencies import obtener_usuario_actual


router = APIRouter(prefix="/auth", tags=["Autenticación"])
password_hash = PasswordHash.recommended()


@router.post(
    "/register",
    response_model=RegistroRespuesta,
    status_code=status.HTTP_201_CREATED,
)
def registrar_usuario(
    datos: RegistroUsuario,
    db: Session = Depends(get_db),
):
    usuario_existente = db.scalar(
        select(Usuario).where(
            (Usuario.email == datos.email)
            | (Usuario.dni == datos.dni)
        )
    )

    if usuario_existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El correo electrónico o el DNI ya están registrados.",
        )

    nuevo_usuario = Usuario(
        nombre=datos.nombre,
        apellido=datos.apellido,
        dni=datos.dni,
        fecha_nacimiento=datos.fecha_nacimiento,
        email=str(datos.email),
        password_hash=password_hash.hash(datos.password),
        activo=True,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )

    try:
        db.add(nuevo_usuario)
        db.commit()
    except IntegrityError:
        #Por si 2 solicitudes llegan al mismo tiempo
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Se produjo un conflicto al intentar crear la cuenta.",
        )

    return RegistroRespuesta(
        mensaje="Cuenta creada correctamente. Ya podés iniciar sesión.",
        email=nuevo_usuario.email,
    )


@router.post(
    "/login", 
    response_model=TokenRespuesta)
def iniciar_sesion(
    datos: LoginUsuario,
    db: Session = Depends(get_db),
):
    usuario = db.scalar(
        select(Usuario).where(Usuario.email == str(datos.email))
    )

    if (
        usuario is None
        or not password_hash.verify(
            datos.password,
            usuario.password_hash,
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No se pudo iniciar sesión",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No se pudo iniciar sesión",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = crear_access_token(usuario.id)

    return TokenRespuesta(access_token=token)


@router.get("/me", response_model=UsuarioActualRespuesta)
def obtener_mi_perfil(
    usuario: Usuario = Depends(obtener_usuario_actual),
):
    return usuario


@router.put("/me", response_model=UsuarioActualRespuesta)
def actualizar_mi_perfil(
    datos: ActualizarPerfilUsuario,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    dni_existente = db.scalar(
        select(Usuario).where(
            Usuario.dni == datos.dni,
            Usuario.id != usuario.id,
        )
    )
    if dni_existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El DNI ya está registrado.",
        )

    usuario.nombre = datos.nombre
    usuario.apellido = datos.apellido
    usuario.dni = datos.dni
    usuario.fecha_nacimiento = datos.fecha_nacimiento
    usuario.updated_at = datetime.now()

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Se produjo un conflicto al actualizar el perfil.",
        )

    return usuario


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def dar_de_baja_mi_cuenta(
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    usuario.activo = False
    usuario.updated_at = datetime.now()
    db.commit()