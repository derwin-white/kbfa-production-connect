import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.tags import Tag
from app.schemas.tags import TagCreate, TagOut

router = APIRouter(prefix="/tags", tags=["tags"])


@router.get("/", response_model=list[TagOut])
async def list_tags(
    db: AsyncSession = Depends(get_db),
    tag_type: str | None = Query(None, description="'skill' | 'equipment' | 'role'"),
    q: str | None = Query(None, description="Fuzzy label/alias search, e.g. 'DP'"),
):
    """List/search controlled-vocabulary tags. `q` matches by alias
    (exact, case-insensitive) or trigram similarity on the label — the
    same alias+fuzzy pattern validated in the prototype queries.
    """
    stmt = select(Tag).where(Tag.is_active.is_(True))
    if tag_type:
        stmt = stmt.where(Tag.tag_type == tag_type)
    if q:
        stmt = stmt.where(or_(Tag.label.ilike(q), Tag.label.op("%")(q), Tag.aliases.any(q)))
    stmt = stmt.order_by(Tag.tag_type, Tag.category, Tag.label)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.post("/", response_model=TagOut, status_code=201)
async def create_tag(payload: TagCreate, db: AsyncSession = Depends(get_db)):
    tag = Tag(tag_type=payload.tag_type, label=payload.label, category=payload.category, aliases=payload.aliases)
    db.add(tag)
    await db.commit()
    await db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=204)
async def deactivate_tag(tag_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    tag = (await db.execute(select(Tag).where(Tag.id == tag_id))).scalar_one_or_none()
    if tag is not None:
        tag.is_active = False
        await db.commit()
