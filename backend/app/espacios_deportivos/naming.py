import re
import unicodedata

from app.models.espacio_deportivo import TipoEspacio


_TIPO_EN_NOMBRE = {
    TipoEspacio.FUTBOL: "Futbol",
    TipoEspacio.PADDLE: "Paddle",
    TipoEspacio.BASQUET: "Basquet",
    TipoEspacio.TENIS: "Tenis",
    TipoEspacio.VOLEY: "Voley",
}


def _normalizar_segmento(valor: str) -> str:
    sin_acentos = unicodedata.normalize("NFKD", valor)
    ascii_simple = sin_acentos.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"_+", "_", re.sub(r"[^A-Za-z0-9]+", "_", ascii_simple)).strip(
        "_"
    )


def generar_nombre_espacio(
    sede_nombre: str,
    direccion: str,
    tipo: TipoEspacio,
    numero: int,
) -> str:
    return "_".join(
        (
            _normalizar_segmento(sede_nombre),
            _normalizar_segmento(direccion),
            _TIPO_EN_NOMBRE[tipo],
            str(numero),
        )
    )
