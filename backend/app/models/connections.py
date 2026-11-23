import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Connection(Base):
    __tablename__ = "connections"

    id: Mapped[uuid.UUID] = mapped_column(UUID, primary_key=True, server_default=text("uuid_generate_v4()"))
    requester_entity_id: Mapped[uuid.UUID] = mapped_column(UUID, ForeignKey("entities.id", ondelete="CASCADE"))
    recipient_entity_id: Mapped[uuid.UUID] = mapped_column(UUID, ForeignKey("entities.id", ondelete="CASCADE"))
    status: Mapped[str] = mapped_column(Text, default="pending")
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(server_default=text("now()"))
    responded_at: Mapped[datetime | None] = mapped_column(nullable=True)
