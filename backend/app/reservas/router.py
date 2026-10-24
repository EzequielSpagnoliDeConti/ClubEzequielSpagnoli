from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.espacio_deportivo import EspacioDeportivo
from app.models.reserva import EstadoReserva, Reserva
from app.models.usuario import Usuario
from app.reservas.schemas import ReservaDatos, ReservaRespuesta


router = APIRouter(prefix="/reservas", tags=["Reservas"])


def validar_referencias_y_disponibilidad(
    datos: ReservaDatos,
    db: Session,
    reserva_id: int | None = None,
) -> None:
    usuario = db.get(Usuario, datos.usuario_id)
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado.",
        )
    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No se pueden crear reservas para un usuario inactivo.",
        )

    espacio = db.get(EspacioDeportivo, datos.espacio_deportivo_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )

    condiciones = [
        Reserva.espacio_deportivo_id == datos.espacio_deportivo_id,
        Reserva.fecha == datos.fecha,
        Reserva.estado == EstadoReserva.ACTIVA,
        Reserva.hora_inicio < datos.hora_fin,
        Reserva.hora_fin > datos.hora_inicio,
    ]
    if reserva_id is not None:
        condiciones.append(Reserva.id != reserva_id)

    reserva_conflictiva = db.scalar(
        select(Reserva.id).where(*condiciones).limit(1)
    )
    if reserva_conflictiva is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El espacio ya tiene una reserva activa en ese horario.",
        )


@router.get("", response_model=list[ReservaRespuesta])
def listar_reservas(db: Session = Depends(get_db)):
    return db.scalars(select(Reserva).order_by(Reserva.id)).all()


@router.post(
    "",
    response_model=ReservaRespuesta,
    status_code=status.HTTP_201_CREATED,
)
def crear_reserva(datos: ReservaDatos, db: Session = Depends(get_db)):
    validar_referencias_y_disponibilidad(datos, db)
    ahora = datetime.now()
    reserva = Reserva(
        **datos.model_dump(),
        estado=EstadoReserva.ACTIVA,
        created_at=ahora,
        updated_at=ahora,
        cancelada_at=None,
    )
    db.add(reserva)
    db.commit()
    db.refresh(reserva)
    return reserva


@router.get("/{reserva_id}", response_model=ReservaRespuesta)
def obtener_reserva(reserva_id: int, db: Session = Depends(get_db)):
    reserva = db.get(Reserva, reserva_id)
    if reserva is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada.",
        )
    return reserva


@router.put("/{reserva_id}", response_model=ReservaRespuesta)
def actualizar_reserva(
    reserva_id: int,
    datos: ReservaDatos,
    db: Session = Depends(get_db),
):
    reserva = db.get(Reserva, reserva_id)
    if reserva is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada.",
        )
    if reserva.estado != EstadoReserva.ACTIVA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Solo se pueden modificar reservas activas.",
        )

    validar_referencias_y_disponibilidad(datos, db, reserva_id)
    for campo, valor in datos.model_dump().items():
        setattr(reserva, campo, valor)
    reserva.updated_at = datetime.now()

    db.commit()
    db.refresh(reserva)
    return reserva


@router.delete(
    "/{reserva_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def cancelar_reserva(reserva_id: int, db: Session = Depends(get_db)):
    reserva = db.get(Reserva, reserva_id)
    if reserva is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada.",
        )
    if reserva.estado == EstadoReserva.FINALIZADA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No se puede cancelar una reserva finalizada.",
        )

    if reserva.estado != EstadoReserva.CANCELADA:
        ahora = datetime.now()
        reserva.estado = EstadoReserva.CANCELADA
        reserva.cancelada_at = ahora
        reserva.updated_at = ahora
        db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
