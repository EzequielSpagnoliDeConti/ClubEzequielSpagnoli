from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.espacios_deportivos.naming import generar_nombre_espacio
from app.models.espacio_deportivo import EspacioDeportivo
from app.models.sede import Sede
from app.sedes.schemas import SedeDatos, SedeRespuesta


router = APIRouter(prefix="/sedes", tags=["Sedes"])


@router.get("", response_model=list[SedeRespuesta])
def listar_sedes(db: Session = Depends(get_db)):
    return db.scalars(select(Sede).order_by(Sede.id)).all()


@router.post(
    "",
    response_model=SedeRespuesta,
    status_code=status.HTTP_201_CREATED,
)
def crear_sede(datos: SedeDatos, db: Session = Depends(get_db)):
    sede = Sede(**datos.model_dump(), created_at=datetime.now())
    db.add(sede)
    db.commit()
    db.refresh(sede)
    return sede


@router.get("/{sede_id}", response_model=SedeRespuesta)
def obtener_sede(sede_id: int, db: Session = Depends(get_db)):
    sede = db.get(Sede, sede_id)
    if sede is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )
    return sede


@router.put("/{sede_id}", response_model=SedeRespuesta)
def actualizar_sede(
    sede_id: int,
    datos: SedeDatos,
    db: Session = Depends(get_db),
):
    sede = db.get(Sede, sede_id)
    if sede is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )

    for campo, valor in datos.model_dump().items():
        setattr(sede, campo, valor)

    espacios = db.scalars(
        select(EspacioDeportivo).where(EspacioDeportivo.sede_id == sede_id)
    ).all()
    for espacio in espacios:
        espacio.nombre = generar_nombre_espacio(
            sede.nombre,
            sede.direccion,
            espacio.tipo,
            espacio.numero,
        )

    db.commit()
    db.refresh(sede)
    return sede


@router.delete(
    "/{sede_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def eliminar_sede(sede_id: int, db: Session = Depends(get_db)):
    sede = db.get(Sede, sede_id)
    if sede is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )

    tiene_espacios = db.scalar(
        select(EspacioDeportivo.id)
        .where(EspacioDeportivo.sede_id == sede_id)
        .limit(1)
    )
    if tiene_espacios is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No se puede eliminar una sede que tiene espacios deportivos.",
        )

    db.delete(sede)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
