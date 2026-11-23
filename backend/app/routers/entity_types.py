from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.entities import EntityType
from app.schemas.entities import EntityTypeOut

router = APIRouter(prefix="/entity-types", tags=["entity-types"])


@router.get("/", response_model=list[EntityTypeOut])
async def list_entity_types(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(EntityType).order_by(EntityType.kind, EntityType.label))
    return result.scalars().all()
