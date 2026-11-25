import { useQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import { EntityCard } from "../components/EntityCard";
import { TagChip } from "../components/TagChip";

const RADIUS_OPTIONS = [5, 10, 25, 50, 100];
const VIEW_MODES = ["cards", "list"] as const;
type ViewMode = (typeof VIEW_MODES)[number];
const VIEW_STORAGE_KEY = "kbfa.search.viewMode";

function loadStoredViewMode(): ViewMode {
  if (typeof window === "undefined") return "cards";
  const stored = window.localStorage.getItem(VIEW_STORAGE_KEY);
  return stored === "list" ? "list" : "cards";
}

export function SearchPage() {
  const [q, setQ] = useState("");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [entityTypeCode, setEntityTypeCode] = useState("");
  const [tagQuery, setTagQuery] = useState("");
  const [useLocation, setUseLocation] = useState(false);
  const [coords, setCoords] = useState<{ latitude: number; longitude: number } | null>(null);
  const [radiusMiles, setRadiusMiles] = useState(25);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>(loadStoredViewMode);

  function changeViewMode(mode: ViewMode) {
    setViewMode(mode);
    window.localStorage.setItem(VIEW_STORAGE_KEY, mode);
  }

  const entityTypesQuery = useQuery({
    queryKey: ["entity-types"],
    queryFn: () => api.entityTypes.list(),
  });

  const tagSuggestionsQuery = useQuery({
    queryKey: ["tags", tagQuery],
    queryFn: () => api.tags.list({ q: tagQuery || undefined }),
    enabled: tagQuery.length > 0,
  });

  const searchParams = useMemo(
    () => ({
      q: q || undefined,
      tag_ids: selectedTagIds.length ? selectedTagIds : undefined,
      entity_type_code: entityTypeCode || undefined,
      latitude: useLocation ? coords?.latitude : undefined,
      longitude: useLocation ? coords?.longitude : undefined,
      radius_miles: useLocation ? radiusMiles : undefined,
      limit: 25,
    }),
    [q, selectedTagIds, entityTypeCode, useLocation, coords, radiusMiles],
  );

  const resultsQuery = useQuery({
    queryKey: ["entity-search", searchParams],
    queryFn: () => api.entities.search(searchParams),
  });

  function handleUseLocation() {
    setLocationError(null);
    if (!navigator.geolocation) {
      setLocationError("Geolocation isn't available in this browser.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setCoords({ latitude: position.coords.latitude, longitude: position.coords.longitude });
        setUseLocation(true);
      },
      () => setLocationError("Couldn't get your location — check browser permissions."),
    );
  }

  function toggleTag(tagId: string) {
    setSelectedTagIds((prev) =>
      prev.includes(tagId) ? prev.filter((id) => id !== tagId) : [...prev, tagId],
    );
  }

  const selectedTags = tagSuggestionsQuery.data?.filter((t) => selectedTagIds.includes(t.id)) ?? [];

  return (
    <>
      <div className="tag-legend">
        <span className="tag-legend__label">Tag colors:</span>
        <span className="tag-legend__item">
          <span className="tag-chip tag-chip--role">Role</span>
          <span className="tag-legend__hint">what someone does on a production</span>
        </span>
        <span className="tag-legend__item">
          <span className="tag-chip tag-chip--skill">Skill</span>
          <span className="tag-legend__hint">what someone can do</span>
        </span>
        <span className="tag-legend__item">
          <span className="tag-chip tag-chip--equipment">Equipment</span>
          <span className="tag-legend__hint">what someone owns or operates</span>
        </span>
      </div>
      <div className="search-page">
        <div className="search-page__filters">
          <h2>Find production talent &amp; businesses</h2>

        <label className="field">
          <span>Search</span>
          <input
            type="text"
            placeholder="e.g. gaffer, drone pilot, RED Komodo..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Type</span>
          <select value={entityTypeCode} onChange={(e) => setEntityTypeCode(e.target.value)}>
            <option value="">All</option>
            {entityTypesQuery.data?.map((t) => (
              <option key={t.id} value={t.code}>
                {t.label}
              </option>
            ))}
          </select>
        </label>

        <label className="field">
          <span>Skill / equipment / role</span>
          <input
            type="text"
            placeholder="Start typing to find a tag..."
            value={tagQuery}
            onChange={(e) => setTagQuery(e.target.value)}
          />
        </label>
        {tagQuery && tagSuggestionsQuery.data && (
          <div className="tag-suggestions">
            {tagSuggestionsQuery.data.map((tag) => (
              <button
                key={tag.id}
                type="button"
                className={`tag-suggestion ${selectedTagIds.includes(tag.id) ? "tag-suggestion--selected" : ""}`}
                onClick={() => toggleTag(tag.id)}
              >
                {tag.label}
              </button>
            ))}
          </div>
        )}
        {selectedTags.length > 0 && (
          <div className="selected-tags">
            {selectedTags.map((tag) => (
              <button key={tag.id} type="button" className="selected-tag" onClick={() => toggleTag(tag.id)}>
                {tag.label} ✕
              </button>
            ))}
          </div>
        )}

        <div className="field field--location">
          <label className="checkbox-field">
            <input
              type="checkbox"
              checked={useLocation}
              onChange={(e) => (e.target.checked ? handleUseLocation() : setUseLocation(false))}
            />
            <span>Near me</span>
          </label>
          {useLocation && (
            <select value={radiusMiles} onChange={(e) => setRadiusMiles(Number(e.target.value))}>
              {RADIUS_OPTIONS.map((miles) => (
                <option key={miles} value={miles}>
                  within {miles} mi
                </option>
              ))}
            </select>
          )}
        </div>
        {locationError && <p className="field-error">{locationError}</p>}
      </div>

      <div className="search-page__results">
        <div className="view-toggle" role="group" aria-label="Results view">
          {VIEW_MODES.map((mode) => (
            <button
              key={mode}
              type="button"
              className={`view-toggle__btn ${viewMode === mode ? "active" : ""}`}
              onClick={() => changeViewMode(mode)}
            >
              {mode === "cards" ? "Cards" : "List"}
            </button>
          ))}
        </div>

        {resultsQuery.isLoading && <p>Searching…</p>}
        {resultsQuery.isError && <p className="field-error">Couldn't load results. Is the API running?</p>}
        {resultsQuery.data && resultsQuery.data.length === 0 && <p>No matches. Try broadening your filters.</p>}

        {viewMode === "cards" ? (
          <div className="entity-grid">
            {resultsQuery.data?.map((entity) => (
              <EntityCard key={entity.id} entity={entity} />
            ))}
          </div>
        ) : (
          resultsQuery.data &&
          resultsQuery.data.length > 0 && (
            <table className="entity-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Type</th>
                  <th>Headline / Location</th>
                  <th>Tags</th>
                  {useLocation && <th>Distance</th>}
                </tr>
              </thead>
              <tbody>
                {resultsQuery.data.map((entity) => {
                  const typeLabel = entityTypesQuery.data?.find((t) => t.id === entity.entity_type_id)?.label;
                  return (
                    <tr key={entity.id}>
                      <td>
                        <Link to={`/entities/${entity.id}`}>{entity.name}</Link>
                      </td>
                      <td>{typeLabel ?? "—"}</td>
                      <td>
                        {entity.headline && <div>{entity.headline}</div>}
                        {entity.location_label && <div className="entity-card__location">{entity.location_label}</div>}
                      </td>
                      <td>
                        {entity.tags.length > 0 && (
                          <div className="entity-card__tags">
                            {entity.tags.slice(0, 6).map((tag) => (
                              <TagChip key={tag.id} tag={tag} />
                            ))}
                          </div>
                        )}
                      </td>
                      {useLocation && <td>{entity.distance_miles != null ? `${entity.distance_miles.toFixed(1)} mi` : "—"}</td>}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )
        )}
      </div>
    </div>
    </>
  );
}
