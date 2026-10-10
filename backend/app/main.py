from fastapi import FastAPI

from app.auth.router import router as auth_router

app = FastAPI(
    title="ClubEzequielSpagnoli API",
    description="API para la gestión de espacios deportivos",
    version="1.0.0",
)

app.include_router(auth_router)


@app.get("/health")
def health():
    return {"status": "ok"}