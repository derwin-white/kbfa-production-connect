import uuid
from datetime import datetime

from sqlalchemy import ARRAY, Boolean, ForeignKey, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Tag(Base):
    __tablename__ = "tags"

    id: Mapped[uuid.UUID] = mapped_column(UUID, primary_key=True, server_default=text("uuid_generate_v4()"))
    tag_type: Mapped[str] = mapped_column(Text)
    label: Mapped[str] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(Text)
    aliases: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(server_default=text("now()"))


class EntityTag(Base):
    __tablename__ = "entity_tags"

    entity_id: Mapped[uuid.UUID] = mapped_column(UUID, ForeignKey("entities.id", ondelete="CASCADE"), primary_key=True)
    tag_id: Mapped[uuid.UUID] = mapped_column(UUID, ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True)
    added_at: Mapped[datetime] = mapped_column(server_default=text("now()"))
