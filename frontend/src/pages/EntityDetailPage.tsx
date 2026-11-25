import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import { TagChip } from "../components/TagChip";
import type { Tag } from "../api/types";

const TAG_SECTIONS: { tagType: Tag["tag_type"]; heading: string }[] = [
  { tagType: "role", heading: "Roles" },
  { tagType: "skill", heading: "Skills" },
  { tagType: "equipment", heading: "Equipment" },
];

export function EntityDetailPage() {
  const { entityId } = useParams<{ entityId: string }>();

  const entityQuery = useQuery({
    queryKey: ["entity", entityId],
    queryFn: () => api.entities.get(entityId!),
    enabled: Boolean(entityId),
  });

  const connectionsQuery = useQuery({
    queryKey: ["connections", entityId, "accepted"],
    queryFn: () => api.connections.listForEntity(entityId!, "accepted"),
    enabled: Boolean(entityId),
  });

  const secondDegreeQuery = useQuery({
    queryKey: ["connections", entityId, "second-degree"],
    queryFn: () => api.connections.secondDegree(entityId!),
    enabled: Boolean(entityId),
  });

  if (entityQuery.isLoading) return <p>Loading…</p>;
  if (entityQuery.isError || !entityQuery.data) return <p className="field-error">Entity not found.</p>;

  const entity = entityQuery.data;

  return (
    <div className="entity-detail">
      <Link to="/" className="back-link">
        ← Back to search
      </Link>
      <h1>{entity.name}</h1>
      {entity.headline && <p className="entity-detail__headline">{entity.headline}</p>}
      {entity.location_label && <p className="entity-detail__location">📍 {entity.location_label}</p>}
      {entity.bio && <p className="entity-detail__bio">{entity.bio}</p>}

      {TAG_SECTIONS.map(({ tagType, heading }) => {
        const tagsOfType = entity.tags.filter((tag) => tag.tag_type === tagType);
        if (tagsOfType.length === 0) return null;
        return (
          <section key={tagType}>
            <h2>{heading}</h2>
            <div className="entity-card__tags">
              {tagsOfType.map((tag) => (
                <TagChip key={tag.id} tag={tag} />
              ))}
            </div>
          </section>
        );
      })}

      {entity.free_text_skills.length > 0 && (
        <section>
          <h2>Also lists</h2>
          <ul className="plain-list">
            {entity.free_text_skills.map((skill) => (
              <li key={skill}>{skill}</li>
            ))}
          </ul>
        </section>
      )}

      {Object.keys(entity.contact).length > 0 && (
        <section>
          <h2>Contact</h2>
          <ul className="plain-list">
            {Object.entries(entity.contact).map(([key, value]) => (
              <li key={key}>
                <strong>{key}:</strong> {String(value)}
              </li>
            ))}
          </ul>
        </section>
      )}

      <section>
        <h2>Connections</h2>
        {connectionsQuery.data && connectionsQuery.data.length > 0 ? (
          <ul className="plain-list">
            {connectionsQuery.data.map((c) => (
              <li key={c.id}>
                <Link to={`/entities/${c.id}`}>{c.name}</Link>
                {c.headline ? ` — ${c.headline}` : ""}
              </li>
            ))}
          </ul>
        ) : (
          <p>No connections yet.</p>
        )}
      </section>

      {secondDegreeQuery.data && secondDegreeQuery.data.length > 0 && (
        <section>
          <h2>People you may know</h2>
          <ul className="plain-list">
            {secondDegreeQuery.data.map((c) => (
              <li key={c.id}>
                <Link to={`/entities/${c.id}`}>{c.name}</Link>
                {c.headline ? ` — ${c.headline}` : ""}
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
