import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pwdlib import PasswordHash
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth.email import enviar_codigo_restauracion
from app.db.database import get_db
from app.auth.schemas import (
    ActualizarPerfilUsuario,
    LoginUsuario,
    RestablecerPassword,
    RegistroRespuesta,
    RegistroUsuario,
    SolicitarRestablecimiento,
    TokenRespuesta,
    UsuarioActualRespuesta,
)
from app.auth.security import crear_access_token
from app.auth.dependencies import obtener_usuario_actual
from app.core.config import correo_configurado
from app.models.password_reset_token import PasswordResetToken
from app.models.usuario import Usuario


router = APIRouter(prefix="/auth", tags=["Autenticación"])
password_hash = PasswordHash.recommended()
RESET_TOKEN_LIFETIME = timedelta(minutes=30)
RESET_TOKEN_RESEND_COOLDOWN = timedelta(minutes=1)


def _a_utc(fecha: datetime) -> datetime:
    if fecha.tzinfo is None:
        return fecha.replace(tzinfo=timezone.utc)
    return fecha.astimezone(timezone.utc)


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

    token = crear_access_token(usuario.id, usuario.token_version)

    return TokenRespuesta(access_token=token)


@router.post(
    "/forgot-password",
    status_code=status.HTTP_202_ACCEPTED,
)
def solicitar_restauracion(
    datos: SolicitarRestablecimiento,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    if not correo_configurado():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="El servicio de correo no está configurado.",
        )

    ahora = datetime.now(timezone.utc)
    db.execute(
        delete(PasswordResetToken).where(
            PasswordResetToken.expires_at <= ahora
        )
    )
    usuario = db.scalar(
        select(Usuario).where(
            Usuario.email == str(datos.email),
            Usuario.activo.is_(True),
        )
    )

    if usuario is not None:
        reset_existente = db.get(PasswordResetToken, usuario.id)
        puede_enviar = (
            reset_existente is None
            or ahora - _a_utc(reset_existente.created_at)
            >= RESET_TOKEN_RESEND_COOLDOWN
        )
        if puede_enviar:
            token = secrets.token_urlsafe(32)
            reset_token = PasswordResetToken(
                user_id=usuario.id,
                token_hash=hashlib.sha256(token.encode()).hexdigest(),
                created_at=ahora,
                expires_at=ahora + RESET_TOKEN_LIFETIME,
            )
            if reset_existente is None:
                db.add(reset_token)
            else:
                reset_existente.token_hash = reset_token.token_hash
                reset_existente.created_at = reset_token.created_at
                reset_existente.expires_at = reset_token.expires_at
            db.commit()
            background_tasks.add_task(
                enviar_codigo_restauracion,
                usuario.email,
                token,
            )

    return {
        "mensaje": (
            "Si el correo corresponde a una cuenta activa, recibirás "
            "instrucciones para restablecer la contraseña."
        )
    }


@router.post("/reset-password")
def restablecer_contrasena(
    datos: RestablecerPassword,
    db: Session = Depends(get_db),
):
    usuario = db.scalar(
        select(Usuario).where(
            Usuario.email == str(datos.email),
            Usuario.activo.is_(True),
        )
    )
    ahora = datetime.now(timezone.utc)
    reset_token = (
        db.get(PasswordResetToken, usuario.id)
        if usuario is not None
        else None
    )
    hash_token = hashlib.sha256(datos.token.encode()).hexdigest()

    if (
        usuario is None
        or reset_token is None
        or _a_utc(reset_token.expires_at) <= ahora
        or not secrets.compare_digest(reset_token.token_hash, hash_token)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El código no es válido o venció.",
        )

    usuario.password_hash = password_hash.hash(datos.password)
    usuario.token_version += 1
    usuario.updated_at = datetime.now()
    db.delete(reset_token)
    db.commit()
    return {"mensaje": "La contraseña se restableció correctamente."}


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