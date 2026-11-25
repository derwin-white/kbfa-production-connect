import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.tags import Tag
from app.schemas.tags import TagCreate, TagOut, TagUpdate

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


async def _find_existing(db: AsyncSession, tag_type: str, label: str) -> Tag | None:
    stmt = select(Tag).where(Tag.tag_type == tag_type, func.lower(Tag.label) == label.lower())
    return (await db.execute(stmt)).scalar_one_or_none()


@router.post("/", response_model=TagOut)
async def create_tag(payload: TagCreate, response: Response, db: AsyncSession = Depends(get_db)):
    """Find-or-create, keyed on the same (tag_type, lower(label)) uniqueness
    the DB enforces — this is the main duplicate-prevention backstop behind
    the frontend's type-ahead: submitting a label that already exists (same
    type, case-insensitive) returns the EXISTING tag (200) instead of
    erroring or creating a second row. A brand-new label creates normally
    (201). Also closes a race where two callers submit the same new label
    at once — the loser's IntegrityError is caught and resolved to the
    winner's row rather than surfaced as a 500.
    """
    existing = await _find_existing(db, payload.tag_type, payload.label)
    if existing is not None:
        response.status_code = 200
        return existing

    tag = Tag(tag_type=payload.tag_type, label=payload.label, category=payload.category, aliases=payload.aliases)
    db.add(tag)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        existing = await _find_existing(db, payload.tag_type, payload.label)
        if existing is None:
            raise
        response.status_code = 200
        return existing

    await db.refresh(tag)
    response.status_code = 201
    return tag


@router.patch("/{tag_id}", response_model=TagOut)
async def update_tag(tag_id: uuid.UUID, payload: TagUpdate, db: AsyncSession = Depends(get_db)):
    """Edits every field of a tag in place (type, label, category,
    aliases) — the admin UI's inline row editor. Keyed on the same
    (tag_type, lower(label)) uniqueness as create; editing into a
    collision with another existing tag is rejected rather than
    silently merged, since that would delete the other tag's identity
    out from under anything already attached to it.
    """
    tag = (await db.execute(select(Tag).where(Tag.id == tag_id))).scalar_one_or_none()
    if tag is None:
        raise HTTPException(status_code=404, detail="Tag not found")

    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(tag, field, value)

    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A tag with this type and label already exists")

    await db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=204)
async def deactivate_tag(tag_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    tag = (await db.execute(select(Tag).where(Tag.id == tag_id))).scalar_one_or_none()
    if tag is not None:
        tag.is_active = False
        await db.commit()
