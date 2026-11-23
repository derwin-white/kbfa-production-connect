import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class EntityTypeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    kind: str
    code: str
    label: str
    description: str | None = None


class TagOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tag_type: str
    label: str
    category: str | None = None


class EntityCreate(BaseModel):
    entity_type_id: int
    name: str
    headline: str | None = None
    bio: str | None = None
    contact: dict = {}
    free_text_skills: list[str] = []
    location_label: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    metadata: dict = {}


class EntityUpdate(BaseModel):
    name: str | None = None
    headline: str | None = None
    bio: str | None = None
    contact: dict | None = None
    free_text_skills: list[str] | None = None
    location_label: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    metadata: dict | None = None
    is_active: bool | None = None


class EntityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    entity_type_id: int
    name: str
    headline: str | None = None
    bio: str | None = None
    contact: dict
    free_text_skills: list[str]
    location_label: str | None = None
    metadata: dict
    is_active: bool
    created_at: datetime
    updated_at: datetime


class EntitySearchResult(EntityOut):
    distance_miles: float | None = None
    rank: float | None = None
    tags: list[TagOut] = []
