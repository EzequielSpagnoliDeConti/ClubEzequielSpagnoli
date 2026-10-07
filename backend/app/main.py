from fastapi import FastAPI

app = FastAPI(
    title="ClubEzequielSpagnoli API",
    description="API para la gestión de espacios deportivos",
    version="1.0.0",
)


@app.get("/health")
def health():
    return {"status": "ok"}