import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.geo import miles_to_meters, point
from app.models.entities import Entity, EntityType
from app.models.tags import EntityTag, Tag
from app.schemas.entities import EntityCreate, EntityOut, EntitySearchResult, EntityUpdate
from app.schemas.tags import TagOut as TagSchema

router = APIRouter(prefix="/entities", tags=["entities"])


def _entity_to_out(entity: Entity, *, distance_miles: float | None = None, rank: float | None = None) -> EntitySearchResult:
    return EntitySearchResult(
        id=entity.id,
        entity_type_id=entity.entity_type_id,
        name=entity.name,
        headline=entity.headline,
        bio=entity.bio,
        contact=entity.contact,
        free_text_skills=entity.free_text_skills,
        location_label=entity.location_label,
        metadata=entity.metadata_,
        is_active=entity.is_active,
        created_at=entity.created_at,
        updated_at=entity.updated_at,
        distance_miles=distance_miles,
        rank=rank,
        tags=[TagSchema.model_validate(t) for t in entity.tags],
    )


@router.get("/", response_model=list[EntitySearchResult])
async def search_entities(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(None, description="Free-text search across name/headline/bio/free-text skills"),
    tag_ids: list[uuid.UUID] = Query(default=[], description="Require ALL of these controlled tag ids"),
    entity_type_code: str | None = Query(None, description="e.g. 'crew', 'rental_house'"),
    latitude: float | None = Query(None),
    longitude: float | None = Query(None),
    radius_miles: float = Query(25.0, gt=0),
    limit: int = Query(25, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Faceted entity search — mirrors the queries validated in
    db/schema/002_prototype_queries.sql: full-text + trigram fuzzy
    fallback, controlled-tag AND-faceting, and PostGIS proximity,
    all composable together.
    """
    rank_col = None
    distance_col = None
    extra_cols = []

    if q:
        tsquery = func.plainto_tsquery("english", q)
        rank_col = func.ts_rank(Entity.search_vector, tsquery).label("rank")
        extra_cols.append(rank_col)

    if latitude is not None and longitude is not None:
        origin = point(latitude, longitude)
        distance_col = func.ST_Distance(Entity.location, origin).label("distance_m")
        extra_cols.append(distance_col)

    stmt = select(Entity, *extra_cols).options(selectinload(Entity.tags)).where(Entity.is_active.is_(True))

    if entity_type_code:
        stmt = stmt.join(EntityType).where(EntityType.code == entity_type_code)

    if q:
        tsquery = func.plainto_tsquery("english", q)
        similarity = func.similarity(Entity.name, q)
        stmt = stmt.where(or_(Entity.search_vector.op("@@")(tsquery), similarity > 0.3))

    for tag_id in tag_ids:
        exists_clause = (
            select(EntityTag.entity_id)
            .where(EntityTag.entity_id == Entity.id, EntityTag.tag_id == tag_id)
            .exists()
        )
        stmt = stmt.where(exists_clause)

    if latitude is not None and longitude is not None:
        origin = point(latitude, longitude)
        stmt = stmt.where(Entity.location.isnot(None))
        stmt = stmt.where(func.ST_DWithin(Entity.location, origin, miles_to_meters(radius_miles)))

    if q:
        stmt = stmt.order_by(rank_col.desc())
    elif distance_col is not None:
        stmt = stmt.order_by(distance_col.asc())
    else:
        stmt = stmt.order_by(Entity.name.asc())

    stmt = stmt.limit(limit).offset(offset)

    result = await db.execute(stmt)
    rows = result.all()

    out = []
    for row in rows:
        entity = row[0]
        rank_value = getattr(row, "rank", None)
        distance_m = getattr(row, "distance_m", None)
        distance_miles = (distance_m / 1609.34) if distance_m is not None else None
        out.append(_entity_to_out(entity, distance_miles=distance_miles, rank=rank_value))
    return out


@router.get("/{entity_id}", response_model=EntitySearchResult)
async def get_entity(entity_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    stmt = select(Entity).options(selectinload(Entity.tags)).where(Entity.id == entity_id)
    entity = (await db.execute(stmt)).scalar_one_or_none()
    if entity is None:
        raise HTTPException(status_code=404, detail="Entity not found")
    return _entity_to_out(entity)


@router.post("/", response_model=EntityOut, status_code=201)
async def create_entity(payload: EntityCreate, db: AsyncSession = Depends(get_db)):
    location = None
    if payload.latitude is not None and payload.longitude is not None:
        location = point(payload.latitude, payload.longitude)

    entity = Entity(
        entity_type_id=payload.entity_type_id,
        name=payload.name,
        headline=payload.headline,
        bio=payload.bio,
        contact=payload.contact,
        free_text_skills=payload.free_text_skills,
        location_label=payload.location_label,
        location=location,
        metadata_=payload.metadata,
    )
    db.add(entity)
    await db.commit()
    await db.refresh(entity)
    return EntityOut(
        id=entity.id,
        entity_type_id=entity.entity_type_id,
        name=entity.name,
        headline=entity.headline,
        bio=entity.bio,
        contact=entity.contact,
        free_text_skills=entity.free_text_skills,
        location_label=entity.location_label,
        metadata=entity.metadata_,
        is_active=entity.is_active,
        created_at=entity.created_at,
        updated_at=entity.updated_at,
    )


@router.patch("/{entity_id}", response_model=EntityOut)
async def update_entity(entity_id: uuid.UUID, payload: EntityUpdate, db: AsyncSession = Depends(get_db)):
    entity = (await db.execute(select(Entity).where(Entity.id == entity_id))).scalar_one_or_none()
    if entity is None:
        raise HTTPException(status_code=404, detail="Entity not found")

    data = payload.model_dump(exclude_unset=True, exclude={"latitude", "longitude", "metadata"})
    for field, value in data.items():
        setattr(entity, field, value)

    if payload.metadata is not None:
        entity.metadata_ = payload.metadata

    if payload.latitude is not None and payload.longitude is not None:
        entity.location = point(payload.latitude, payload.longitude)

    await db.commit()
    await db.refresh(entity)
    return EntityOut(
        id=entity.id,
        entity_type_id=entity.entity_type_id,
        name=entity.name,
        headline=entity.headline,
        bio=entity.bio,
        contact=entity.contact,
        free_text_skills=entity.free_text_skills,
        location_label=entity.location_label,
        metadata=entity.metadata_,
        is_active=entity.is_active,
        created_at=entity.created_at,
        updated_at=entity.updated_at,
    )


@router.post("/{entity_id}/tags/{tag_id}", status_code=204)
async def add_entity_tag(entity_id: uuid.UUID, tag_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    entity = (await db.execute(select(Entity).where(Entity.id == entity_id))).scalar_one_or_none()
    if entity is None:
        raise HTTPException(status_code=404, detail="Entity not found")
    tag = (await db.execute(select(Tag).where(Tag.id == tag_id))).scalar_one_or_none()
    if tag is None:
        raise HTTPException(status_code=404, detail="Tag not found")

    existing = (
        await db.execute(select(EntityTag).where(EntityTag.entity_id == entity_id, EntityTag.tag_id == tag_id))
    ).scalar_one_or_none()
    if existing is None:
        db.add(EntityTag(entity_id=entity_id, tag_id=tag_id))
        await db.commit()


@router.delete("/{entity_id}/tags/{tag_id}", status_code=204)
async def remove_entity_tag(entity_id: uuid.UUID, tag_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    existing = (
        await db.execute(select(EntityTag).where(EntityTag.entity_id == entity_id, EntityTag.tag_id == tag_id))
    ).scalar_one_or_none()
    if existing is not None:
        await db.delete(existing)
        await db.commit()
