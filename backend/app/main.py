from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import connections, entities, entity_types, projects, tags

app = FastAPI(title="KBFA Production Connect API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(entity_types.router)
app.include_router(entities.router)
app.include_router(tags.router)
app.include_router(connections.router)
app.include_router(projects.router)


@app.get("/health")
async def health():
    return {"status": "ok"}
