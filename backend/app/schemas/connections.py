import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


class ConnectionCreate(BaseModel):
    requester_entity_id: uuid.UUID
    recipient_entity_id: uuid.UUID
    note: str | None = None


class ConnectionStatusUpdate(BaseModel):
    status: Literal["accepted", "declined"]


class ConnectionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    requester_entity_id: uuid.UUID
    recipient_entity_id: uuid.UUID
    status: str
    note: str | None = None
    created_at: datetime
    responded_at: datetime | None = None


class ConnectedEntityOut(BaseModel):
    id: uuid.UUID
    name: str
    headline: str | None = None
    connection_status: str
