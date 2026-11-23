import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.geo import point
from app.models.entities import Entity
from app.models.projects import Project, ProjectMember
from app.models.tags import Tag
from app.schemas.projects import ProjectCreate, ProjectMemberCreate, ProjectMemberOut, ProjectOut

router = APIRouter(prefix="/projects", tags=["projects"])


def _to_out(project: Project) -> ProjectOut:
    return ProjectOut(
        id=project.id,
        owner_entity_id=project.owner_entity_id,
        name=project.name,
        description=project.description,
        project_type=project.project_type,
        status=project.status,
        location_label=project.location_label,
        start_date=project.start_date,
        end_date=project.end_date,
        metadata=project.metadata_,
        created_at=project.created_at,
        updated_at=project.updated_at,
    )


@router.get("/", response_model=list[ProjectOut])
async def list_projects(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(None, description="Free-text search across name/type/description"),
    status: str | None = Query(None),
    limit: int = Query(25, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    stmt = select(Project)
    if q:
        tsquery = func.plainto_tsquery("english", q)
        stmt = stmt.where(Project.search_vector.op("@@")(tsquery))
    if status:
        stmt = stmt.where(Project.status == status)
    stmt = stmt.order_by(Project.created_at.desc()).limit(limit).offset(offset)
    projects = (await db.execute(stmt)).scalars().all()
    return [_to_out(p) for p in projects]


@router.get("/{project_id}", response_model=ProjectOut)
async def get_project(project_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    project = (await db.execute(select(Project).where(Project.id == project_id))).scalar_one_or_none()
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return _to_out(project)


@router.post("/", response_model=ProjectOut, status_code=201)
async def create_project(payload: ProjectCreate, db: AsyncSession = Depends(get_db)):
    location = None
    if payload.latitude is not None and payload.longitude is not None:
        location = point(payload.latitude, payload.longitude)

    project = Project(
        owner_entity_id=payload.owner_entity_id,
        name=payload.name,
        description=payload.description,
        project_type=payload.project_type,
        status=payload.status,
        location_label=payload.location_label,
        location=location,
        start_date=payload.start_date,
        end_date=payload.end_date,
        metadata_=payload.metadata,
    )
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return _to_out(project)


@router.get("/{project_id}/members", response_model=list[ProjectMemberOut])
async def list_project_members(project_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Project roster with role resolved from either a controlled tag or
    free text — the coalesce(tag.label, role_free_text) pattern validated
    in the prototype query."""
    stmt = (
        select(
            ProjectMember.entity_id,
            Entity.name.label("entity_name"),
            func.coalesce(Tag.label, ProjectMember.role_free_text).label("role"),
            ProjectMember.status,
        )
        .join(Entity, Entity.id == ProjectMember.entity_id)
        .outerjoin(Tag, Tag.id == ProjectMember.role_tag_id)
        .where(ProjectMember.project_id == project_id)
    )
    rows = (await db.execute(stmt)).all()
    return [
        ProjectMemberOut(entity_id=row.entity_id, entity_name=row.entity_name, role=row.role, status=row.status)
        for row in rows
    ]


@router.post("/{project_id}/members", response_model=ProjectMemberOut, status_code=201)
async def add_project_member(project_id: uuid.UUID, payload: ProjectMemberCreate, db: AsyncSession = Depends(get_db)):
    project = (await db.execute(select(Project).where(Project.id == project_id))).scalar_one_or_none()
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    entity = (await db.execute(select(Entity).where(Entity.id == payload.entity_id))).scalar_one_or_none()
    if entity is None:
        raise HTTPException(status_code=404, detail="Entity not found")
    if payload.role_tag_id is None and not payload.role_free_text:
        raise HTTPException(status_code=400, detail="Provide role_tag_id or role_free_text")

    member = ProjectMember(
        project_id=project_id,
        entity_id=payload.entity_id,
        role_tag_id=payload.role_tag_id,
        role_free_text=payload.role_free_text,
        status=payload.status,
    )
    db.add(member)
    await db.commit()

    role_label = payload.role_free_text
    if payload.role_tag_id is not None:
        tag = (await db.execute(select(Tag).where(Tag.id == payload.role_tag_id))).scalar_one_or_none()
        role_label = tag.label if tag else role_label

    return ProjectMemberOut(entity_id=entity.id, entity_name=entity.name, role=role_label, status=member.status)
