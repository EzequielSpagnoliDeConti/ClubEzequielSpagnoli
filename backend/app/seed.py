from datetime import datetime, time
from decimal import Decimal
from random import randint

from sqlalchemy import select

from app.db.database import SessionLocal
from app.models.espacio_deportivo import EspacioDeportivo, TipoEspacio
from app.models.sede import Sede
from app.models.tarifa import Tarifa


SEDES = (
    {
        "nombre": "Moreno",
        "direccion": "Av. Victorica 1250, Moreno",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 5"),
            (TipoEspacio.FUTBOL, "Cancha de futbol 7"),
            (TipoEspacio.PADDLE, "Cancha de paddle 1"),
            (TipoEspacio.PADDLE, "Cancha de paddle 2"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley"),
        ),
    },
    {
        "nombre": "Moron",
        "direccion": "Av. Rivadavia 17800, Moron",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 5"),
            (TipoEspacio.PADDLE, "Cancha de paddle"),
            (TipoEspacio.TENIS, "Cancha de tenis"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley"),
            (TipoEspacio.VOLEY, "Cancha de voley auxiliar"),
        ),
    },
    {
        "nombre": "Castelar",
        "direccion": "Av. Santa Rosa 2100, Castelar",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 7"),
            (TipoEspacio.PADDLE, "Cancha de paddle"),
            (TipoEspacio.TENIS, "Cancha de tenis 1"),
            (TipoEspacio.TENIS, "Cancha de tenis 2"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley"),
        ),
    },
    {
        "nombre": "Ramos Mejia",
        "direccion": "Av. de Mayo 950, Ramos Mejia",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 5"),
            (TipoEspacio.FUTBOL, "Cancha de futbol 7"),
            (TipoEspacio.PADDLE, "Cancha de paddle"),
            (TipoEspacio.TENIS, "Cancha de tenis"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley"),
        ),
    },
    {
        "nombre": "Ituzaingo",
        "direccion": "Av. Ratti 800, Ituzaingo",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 5"),
            (TipoEspacio.PADDLE, "Cancha de paddle 1"),
            (TipoEspacio.PADDLE, "Cancha de paddle 2"),
            (TipoEspacio.TENIS, "Cancha de tenis"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley"),
        ),
    },
    {
        "nombre": "Haedo",
        "direccion": "Av. Presidente Peron 250, Haedo",
        "espacios": (
            (TipoEspacio.FUTBOL, "Cancha de futbol 5"),
            (TipoEspacio.PADDLE, "Cancha de paddle"),
            (TipoEspacio.TENIS, "Cancha de tenis"),
            (TipoEspacio.BASQUET, "Cancha de basquet"),
            (TipoEspacio.VOLEY, "Cancha de voley 1"),
            (TipoEspacio.VOLEY, "Cancha de voley 2"),
        ),
    },
)


def seed() -> tuple[int, int, int]:
    ahora = datetime.now()
    sedes_creadas = 0
    espacios_creados = 0
    tarifas_creadas = 0

    with SessionLocal.begin() as session:
        sedes_existentes = {
            sede.nombre: sede
            for sede in session.scalars(select(Sede)).all()
        }

        for datos_sede in SEDES:
            sede = sedes_existentes.get(datos_sede["nombre"])
            if sede is None:
                sede = Sede(
                    nombre=datos_sede["nombre"],
                    direccion=datos_sede["direccion"],
                    hora_apertura=time(8, 0),
                    hora_cierre=time(23, 0),
                    created_at=ahora,
                )
                session.add(sede)
                session.flush()
                sedes_existentes[sede.nombre] = sede
                sedes_creadas += 1

            numeros_existentes = set(
                session.scalars(
                    select(EspacioDeportivo.numero).where(
                        EspacioDeportivo.sede_id == sede.id
                    )
                ).all()
            )

            for numero, (tipo, nombre) in enumerate(datos_sede["espacios"], start=1):
                if numero in numeros_existentes:
                    continue
                session.add(
                    EspacioDeportivo(
                        sede_id=sede.id,
                        tipo=tipo,
                        numero=numero,
                        nombre=nombre,
                        created_at=ahora,
                    )
                )
                espacios_creados += 1

        tipos_con_tarifa = set(
            session.scalars(select(Tarifa.tipo_espacio)).all()
        )
        for tipo in TipoEspacio:
            if tipo.value in tipos_con_tarifa:
                continue
            session.add(
                Tarifa(
                    tipo_espacio=tipo.value,
                    precio_por_hora=Decimal(randint(3000, 6000)),
                    updated_at=ahora,
                )
            )
            tarifas_creadas += 1

    return sedes_creadas, espacios_creados, tarifas_creadas


if __name__ == "__main__":
    sedes_creadas, espacios_creados, tarifas_creadas = seed()
    print(
        f"Seed completado: {sedes_creadas} sedes y "
        f"{espacios_creados} espacios deportivos y "
        f"{tarifas_creadas} tarifas agregadas."
    )
