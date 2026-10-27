from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.tarifa import Tarifa
from app.tarifas.schemas import TarifaRespuesta


router = APIRouter(prefix="/tarifas", tags=["Tarifas"])


@router.get("", response_model=list[TarifaRespuesta])
def listar_tarifas(db: Session = Depends(get_db)):
    return db.scalars(select(Tarifa).order_by(Tarifa.tipo_espacio)).all()
