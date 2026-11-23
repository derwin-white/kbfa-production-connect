import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, or_, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.connections import Connection
from app.models.entities import Entity
from app.schemas.connections import ConnectedEntityOut, ConnectionCreate, ConnectionOut, ConnectionStatusUpdate

router = APIRouter(prefix="/connections", tags=["connections"])


@router.post("/", response_model=ConnectionOut, status_code=201)
async def request_connection(payload: ConnectionCreate, db: AsyncSession = Depends(get_db)):
    if payload.requester_entity_id == payload.recipient_entity_id:
        raise HTTPException(status_code=400, detail="An entity cannot connect to itself")

    connection = Connection(
        requester_entity_id=payload.requester_entity_id,
        recipient_entity_id=payload.recipient_entity_id,
        note=payload.note,
    )
    db.add(connection)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A connection between these entities already exists")
    await db.refresh(connection)
    return connection


@router.patch("/{connection_id}", response_model=ConnectionOut)
async def respond_to_connection(connection_id: uuid.UUID, payload: ConnectionStatusUpdate, db: AsyncSession = Depends(get_db)):
    connection = (await db.execute(select(Connection).where(Connection.id == connection_id))).scalar_one_or_none()
    if connection is None:
        raise HTTPException(status_code=404, detail="Connection not found")
    connection.status = payload.status
    connection.responded_at = func.now()
    await db.commit()
    await db.refresh(connection)
    return connection


@router.get("/entity/{entity_id}", response_model=list[ConnectedEntityOut])
async def list_connections(
    entity_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    status: str | None = Query(None, description="Filter to 'pending' | 'accepted' | 'declined'; omit for all"),
):
    """Connections for an entity, direction-agnostic — same
    requester/recipient CASE pattern validated in the prototype query.
    Unlike the prototype (which only looked at accepted edges), this
    returns every status by default so a UI can show pending requests
    too; pass `status=accepted` to match the prototype's narrower view."""
    other_id = case(
        (Connection.requester_entity_id == entity_id, Connection.recipient_entity_id),
        else_=Connection.requester_entity_id,
    )
    stmt = (
        select(Entity.id, Entity.name, Entity.headline, Connection.status)
        .join(Connection, Entity.id == other_id)
        .where(or_(Connection.requester_entity_id == entity_id, Connection.recipient_entity_id == entity_id))
    )
    if status:
        stmt = stmt.where(Connection.status == status)
    rows = (await db.execute(stmt)).all()
    return [
        ConnectedEntityOut(id=row.id, name=row.name, headline=row.headline, connection_status=row.status)
        for row in rows
    ]


@router.get("/entity/{entity_id}/second-degree", response_model=list[ConnectedEntityOut])
async def second_degree_network(entity_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """'People you may know' — entities connected to entity_id's accepted
    1st-degree connections, excluding entity_id itself and anyone already
    directly connected. Mirrors the CTE validated in the prototype query."""
    stmt = text(
        """
        WITH first_degree AS (
            SELECT CASE WHEN c.requester_entity_id = :eid THEN c.recipient_entity_id ELSE c.requester_entity_id END AS entity_id
            FROM connections c
            WHERE (c.requester_entity_id = :eid OR c.recipient_entity_id = :eid) AND c.status = 'accepted'
        )
        SELECT DISTINCT e.id, e.name, e.headline
        FROM connections c
        JOIN first_degree fd ON (c.requester_entity_id = fd.entity_id OR c.recipient_entity_id = fd.entity_id)
        JOIN entities e ON e.id = (CASE WHEN c.requester_entity_id = fd.entity_id THEN c.recipient_entity_id ELSE c.requester_entity_id END)
        WHERE c.status = 'accepted'
          AND e.id != :eid
          AND e.id NOT IN (SELECT entity_id FROM first_degree)
        """
    )
    rows = (await db.execute(stmt, {"eid": str(entity_id)})).all()
    return [
        ConnectedEntityOut(id=row.id, name=row.name, headline=row.headline, connection_status="2nd_degree")
        for row in rows
    ]
