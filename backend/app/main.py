from fastapi import FastAPI

from app.auth.router import router as auth_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ClubEzequielSpagnoli API",
    description="API para la gestión de espacios deportivos",
    version="1.0.0",
)

app.include_router(auth_router)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:51337",
        "http://127.0.0.1:51337",
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}