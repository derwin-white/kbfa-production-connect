import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class ProjectCreate(BaseModel):
    owner_entity_id: uuid.UUID | None = None
    name: str
    description: str | None = None
    project_type: str | None = None
    status: str = "planning"
    location_label: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    start_date: date | None = None
    end_date: date | None = None
    metadata: dict = {}


class ProjectOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_entity_id: uuid.UUID | None = None
    name: str
    description: str | None = None
    project_type: str | None = None
    status: str
    location_label: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    metadata: dict
    created_at: datetime
    updated_at: datetime


class ProjectMemberCreate(BaseModel):
    entity_id: uuid.UUID
    role_tag_id: uuid.UUID | None = None
    role_free_text: str | None = None
    status: str = "confirmed"


class ProjectMemberOut(BaseModel):
    entity_id: uuid.UUID
    entity_name: str
    role: str | None = None
    status: str
