from fastapi import FastAPI

from app.auth.router import router as auth_router
from app.espacios_deportivos.router import router as espacios_deportivos_router
from app.reservas.router import router as reservas_router
from app.sedes.router import router as sedes_router
from app.tarifas.router import router as tarifas_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ClubEzequielSpagnoli API",
    description="API para la gestión de espacios deportivos",
    version="1.0.0",
)

app.include_router(auth_router)
app.include_router(sedes_router)
app.include_router(espacios_deportivos_router)
app.include_router(reservas_router)
app.include_router(tarifas_router)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5000",
        "http://127.0.0.1:5000",
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}