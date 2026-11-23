import uuid

from pydantic import BaseModel, ConfigDict


class TagCreate(BaseModel):
    tag_type: str
    label: str
    category: str | None = None
    aliases: list[str] = []


class TagOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tag_type: str
    label: str
    category: str | None = None
    aliases: list[str]
