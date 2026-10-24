from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.espacios_deportivos.schemas import (
    EspacioDeportivoDatos,
    EspacioDeportivoRespuesta,
)
from app.models.espacio_deportivo import EspacioDeportivo
from app.models.reserva import Reserva
from app.models.sede import Sede


router = APIRouter(
    prefix="/espacios-deportivos",
    tags=["Espacios deportivos"],
)


@router.get("", response_model=list[EspacioDeportivoRespuesta])
def listar_espacios_deportivos(db: Session = Depends(get_db)):
    return db.scalars(
        select(EspacioDeportivo).order_by(EspacioDeportivo.id)
    ).all()


@router.post(
    "",
    response_model=EspacioDeportivoRespuesta,
    status_code=status.HTTP_201_CREATED,
)
def crear_espacio_deportivo(
    datos: EspacioDeportivoDatos,
    db: Session = Depends(get_db),
):
    if db.get(Sede, datos.sede_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )

    espacio = EspacioDeportivo(
        **datos.model_dump(),
        created_at=datetime.now(),
    )
    db.add(espacio)
    db.commit()
    db.refresh(espacio)
    return espacio


@router.get(
    "/{espacio_id}",
    response_model=EspacioDeportivoRespuesta,
)
def obtener_espacio_deportivo(
    espacio_id: int,
    db: Session = Depends(get_db),
):
    espacio = db.get(EspacioDeportivo, espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )
    return espacio


@router.put(
    "/{espacio_id}",
    response_model=EspacioDeportivoRespuesta,
)
def actualizar_espacio_deportivo(
    espacio_id: int,
    datos: EspacioDeportivoDatos,
    db: Session = Depends(get_db),
):
    espacio = db.get(EspacioDeportivo, espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )
    if db.get(Sede, datos.sede_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )

    for campo, valor in datos.model_dump().items():
        setattr(espacio, campo, valor)

    db.commit()
    db.refresh(espacio)
    return espacio


@router.delete(
    "/{espacio_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def eliminar_espacio_deportivo(
    espacio_id: int,
    db: Session = Depends(get_db),
):
    espacio = db.get(EspacioDeportivo, espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )

    tiene_reservas = db.scalar(
        select(Reserva.id)
        .where(Reserva.espacio_deportivo_id == espacio_id)
        .limit(1)
    )
    if tiene_reservas is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No se puede eliminar un espacio que tiene reservas.",
        )

    db.delete(espacio)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
