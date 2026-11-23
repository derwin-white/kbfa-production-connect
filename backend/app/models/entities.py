import uuid
from datetime import datetime

from geoalchemy2 import Geography
from sqlalchemy import ARRAY, Boolean, ForeignKey, SmallInteger, Text, text
from sqlalchemy.dialects.postgresql import JSONB, TSVECTOR, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class EntityType(Base):
    __tablename__ = "entity_types"

    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    kind: Mapped[str] = mapped_column(Text)
    code: Mapped[str] = mapped_column(Text, unique=True)
    label: Mapped[str] = mapped_column(Text)
    description: Mapped[str | None] = mapped_column(Text)


class Entity(Base):
    __tablename__ = "entities"

    id: Mapped[uuid.UUID] = mapped_column(UUID, primary_key=True, server_default=text("uuid_generate_v4()"))
    entity_type_id: Mapped[int] = mapped_column(SmallInteger, ForeignKey("entity_types.id"))
    name: Mapped[str] = mapped_column(Text)
    headline: Mapped[str | None] = mapped_column(Text)
    bio: Mapped[str | None] = mapped_column(Text)
    contact: Mapped[dict] = mapped_column(JSONB, default=dict)
    free_text_skills: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    location_label: Mapped[str | None] = mapped_column(Text)
    location = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSONB, default=dict)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(server_default=text("now()"))
    updated_at: Mapped[datetime] = mapped_column(server_default=text("now()"))
    search_vector = mapped_column(TSVECTOR)

    entity_type: Mapped[EntityType] = relationship()
    tags: Mapped[list["Tag"]] = relationship(secondary="entity_tags", viewonly=True)
