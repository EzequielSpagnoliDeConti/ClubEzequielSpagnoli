from datetime import datetime, time
from decimal import Decimal
from random import randint

from sqlalchemy import select

from app.db.database import SessionLocal
from app.espacios_deportivos.naming import generar_nombre_espacio
from app.models.espacio_deportivo import EspacioDeportivo, TipoEspacio
from app.models.sede import Sede
from app.models.tarifa import Tarifa


SEDES = (
    {
        "nombre": "Moreno",
        "direccion": "Av. Victorica 1250, Moreno",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.PADDLE,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
        ),
    },
    {
        "nombre": "Moron",
        "direccion": "Av. Rivadavia 17800, Moron",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.TENIS,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
            TipoEspacio.VOLEY,
        ),
    },
    {
        "nombre": "Castelar",
        "direccion": "Av. Santa Rosa 2100, Castelar",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.TENIS,
            TipoEspacio.TENIS,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
        ),
    },
    {
        "nombre": "Ramos Mejia",
        "direccion": "Av. de Mayo 950, Ramos Mejia",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.TENIS,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
        ),
    },
    {
        "nombre": "Ituzaingo",
        "direccion": "Av. Ratti 800, Ituzaingo",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.PADDLE,
            TipoEspacio.TENIS,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
        ),
    },
    {
        "nombre": "Haedo",
        "direccion": "Av. Presidente Peron 250, Haedo",
        "espacios": (
            TipoEspacio.FUTBOL,
            TipoEspacio.PADDLE,
            TipoEspacio.TENIS,
            TipoEspacio.BASQUET,
            TipoEspacio.VOLEY,
            TipoEspacio.VOLEY,
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

            espacios_existentes = session.scalars(
                select(EspacioDeportivo).where(
                    EspacioDeportivo.sede_id == sede.id
                )
            ).all()
            for espacio in espacios_existentes:
                espacio.nombre = generar_nombre_espacio(
                    sede.nombre,
                    sede.direccion,
                    espacio.tipo,
                    espacio.numero,
                )

            for numero, tipo in enumerate(datos_sede["espacios"], start=1):
                if numero in numeros_existentes:
                    continue
                session.add(
                    EspacioDeportivo(
                        sede_id=sede.id,
                        tipo=tipo,
                        numero=numero,
                        nombre=generar_nombre_espacio(
                            sede.nombre,
                            sede.direccion,
                            tipo,
                            numero,
                        ),
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
