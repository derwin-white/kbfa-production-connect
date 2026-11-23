import { Link } from "react-router-dom";
import type { EntitySearchResult } from "../api/types";
import { TagChip } from "./TagChip";

export function EntityCard({ entity }: { entity: EntitySearchResult }) {
  return (
    <Link to={`/entities/${entity.id}`} className="entity-card">
      <div className="entity-card__header">
        <h3>{entity.name}</h3>
        {entity.distance_miles != null && (
          <span className="entity-card__distance">{entity.distance_miles.toFixed(1)} mi</span>
        )}
      </div>
      {entity.headline && <p className="entity-card__headline">{entity.headline}</p>}
      {entity.location_label && <p className="entity-card__location">{entity.location_label}</p>}
      {entity.tags.length > 0 && (
        <div className="entity-card__tags">
          {entity.tags.slice(0, 6).map((tag) => (
            <TagChip key={tag.id} tag={tag} />
          ))}
        </div>
      )}
    </Link>
  );
}
