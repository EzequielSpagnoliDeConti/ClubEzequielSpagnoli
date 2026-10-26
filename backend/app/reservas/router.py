from datetime import date, datetime, time, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.espacio_deportivo import EspacioDeportivo
from app.models.reserva import EstadoReserva, Reserva
from app.models.sede import Sede
from app.models.tarifa import Tarifa
from app.models.usuario import Usuario
from app.auth.dependencies import obtener_usuario_actual
from app.reservas.schemas import (
    ReservaDatos,
    ReservaHistorialRespuesta,
    ReservaMiaDatos,
    ReservaRespuesta,
    HorarioDisponibleRespuesta,
)


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


@router.get("/mias", response_model=list[ReservaHistorialRespuesta])
def listar_mis_reservas(
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    reservas = db.execute(
        select(Reserva, EspacioDeportivo, Sede)
        .join(
            EspacioDeportivo,
            Reserva.espacio_deportivo_id == EspacioDeportivo.id,
        )
        .join(Sede, EspacioDeportivo.sede_id == Sede.id)
        .where(Reserva.usuario_id == usuario.id)
        .order_by(Reserva.fecha, Reserva.hora_inicio, Reserva.id)
    ).all()

    return [
        ReservaHistorialRespuesta(
            id=reserva.id,
            espacio_deportivo_id=reserva.espacio_deportivo_id,
            fecha=reserva.fecha,
            hora_inicio=reserva.hora_inicio,
            hora_fin=reserva.hora_fin,
            estado=reserva.estado,
            cancelada_at=reserva.cancelada_at,
            sede_nombre=sede.nombre,
            espacio_nombre=espacio.nombre,
            tipo_espacio=espacio.tipo,
        )
        for reserva, espacio, sede in reservas
    ]


@router.get(
    "/disponibilidad/{espacio_id}",
    response_model=list[HorarioDisponibleRespuesta],
)
def consultar_disponibilidad(
    espacio_id: int,
    fecha: date,
    duracion_horas: int = Query(ge=1, le=2),
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    hoy = date.today()
    if fecha < hoy:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No se puede consultar disponibilidad para una fecha pasada.",
        )

    espacio = db.get(EspacioDeportivo, espacio_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )

    sede = db.get(Sede, espacio.sede_id)
    if sede is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sede no encontrada.",
        )

    apertura = datetime.combine(
        fecha,
        time(sede.hora_apertura.hour, sede.hora_apertura.minute),
    )
    cierre = datetime.combine(
        fecha,
        time(sede.hora_cierre.hour, sede.hora_cierre.minute),
    )
    duracion = timedelta(hours=duracion_horas)
    reservas_activas = db.scalars(
        select(Reserva).where(
            Reserva.espacio_deportivo_id == espacio_id,
            Reserva.fecha == fecha,
            Reserva.estado == EstadoReserva.ACTIVA,
        )
    ).all()

    ahora = datetime.now()
    horarios: list[HorarioDisponibleRespuesta] = []
    inicio = apertura
    while inicio + duracion <= cierre:
        fin = inicio + duracion
        ocupado = any(
            reserva.hora_inicio < fin.time()
            and reserva.hora_fin > inicio.time()
            for reserva in reservas_activas
        )
        if not ocupado and (fecha > hoy or inicio > ahora):
            horarios.append(
                HorarioDisponibleRespuesta(
                    hora_inicio=inicio.time(),
                    hora_fin=fin.time(),
                )
            )
        inicio += timedelta(hours=1)

    return horarios


@router.post(
    "/mias",
    response_model=ReservaRespuesta,
    status_code=status.HTTP_201_CREATED,
)
def crear_mi_reserva(
    datos: ReservaMiaDatos,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    espacio = db.get(EspacioDeportivo, datos.espacio_deportivo_id)
    if espacio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Espacio deportivo no encontrado.",
        )

    tarifa = db.scalar(
        select(Tarifa).where(Tarifa.tipo_espacio == espacio.tipo.value)
    )
    if tarifa is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No hay una tarifa configurada para este deporte.",
        )

    inicio = datetime.combine(datos.fecha, datos.hora_inicio)
    fin = datetime.combine(datos.fecha, datos.hora_fin)
    duracion = fin - inicio
    if datos.fecha < date.today() or duracion not in (
        timedelta(hours=1),
        timedelta(hours=2),
    ):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="La reserva debe ser de una o dos horas y para hoy o una fecha futura.",
        )

    sede = db.get(Sede, espacio.sede_id)
    apertura = datetime.combine(datos.fecha, sede.hora_apertura)
    cierre = datetime.combine(datos.fecha, sede.hora_cierre)
    if inicio < apertura or fin > cierre:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="El horario solicitado está fuera del horario de atención.",
        )

    reserva_datos = ReservaDatos(
        usuario_id=usuario.id,
        espacio_deportivo_id=datos.espacio_deportivo_id,
        fecha=datos.fecha,
        hora_inicio=datos.hora_inicio,
        hora_fin=datos.hora_fin,
    )
    validar_referencias_y_disponibilidad(reserva_datos, db)
    if datos.fecha == date.today() and inicio <= datetime.now():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El horario solicitado ya pasó.",
        )

    ahora = datetime.now()
    reserva = Reserva(
        **reserva_datos.model_dump(),
        estado=EstadoReserva.ACTIVA,
        created_at=ahora,
        updated_at=ahora,
        cancelada_at=None,
    )
    db.add(reserva)
    db.commit()
    db.refresh(reserva)
    return reserva


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
def cancelar_reserva(
    reserva_id: int,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db),
):
    reserva = db.get(Reserva, reserva_id)
    if reserva is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada.",
        )
    if reserva.usuario_id != usuario.id:
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
