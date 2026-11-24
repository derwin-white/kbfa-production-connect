import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { api } from "../api/client";
import type { Tag } from "../api/types";

type TagType = "skill" | "equipment" | "role";

interface TermResolution {
  term: string;
  match: Tag | null;
}

function useDebouncedValue<T>(value: T, delayMs: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(id);
  }, [value, delayMs]);
  return debounced;
}

/**
 * Lets a user attach controlled-vocabulary tags of one type (skill /
 * equipment / role) to something they're creating. Two ways in:
 *  - a type-ahead search against existing tags (the primary duplicate
 *    prevention mechanism — see what's already there before typing a new one)
 *  - a comma-separated freeform field for anything not found, with a live
 *    per-term preview of whether it already exists (so even a typo'd
 *    "duplicate" gets caught before submit).
 * The parent owns `selected` and `freeformValue` and does the actual
 * create-or-attach work on submit — this component is just the picker UI.
 */
export function TagPicker({
  tagType,
  label,
  selected,
  onSelectedChange,
  freeformValue,
  onFreeformChange,
}: {
  tagType: TagType;
  label: string;
  selected: Tag[];
  onSelectedChange: (tags: Tag[]) => void;
  freeformValue: string;
  onFreeformChange: (value: string) => void;
}) {
  const [query, setQuery] = useState("");

  const suggestionsQuery = useQuery({
    queryKey: ["tags", tagType, query],
    queryFn: () => api.tags.list({ tag_type: tagType, q: query || undefined }),
    enabled: query.length > 0,
  });

  const debouncedFreeform = useDebouncedValue(freeformValue, 350);
  const [resolutions, setResolutions] = useState<TermResolution[]>([]);

  useEffect(() => {
    const terms = debouncedFreeform
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);
    if (terms.length === 0) {
      setResolutions([]);
      return;
    }
    let cancelled = false;
    Promise.all(
      terms.map(async (term) => {
        const candidates = await api.tags.list({ tag_type: tagType, q: term });
        const exact = candidates.find((t) => t.label.toLowerCase() === term.toLowerCase());
        return { term, match: exact ?? null };
      }),
    ).then((results) => {
      if (!cancelled) setResolutions(results);
    });
    return () => {
      cancelled = true;
    };
  }, [debouncedFreeform, tagType]);

  function toggle(tag: Tag) {
    if (selected.some((t) => t.id === tag.id)) {
      onSelectedChange(selected.filter((t) => t.id !== tag.id));
    } else {
      onSelectedChange([...selected, tag]);
    }
  }

  return (
    <div className="tag-picker">
      <label className="field">
        <span>{label}</span>
        <input
          type="text"
          placeholder={`Search existing ${label.toLowerCase()}…`}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </label>

      {query && suggestionsQuery.data && (
        <div className="tag-suggestions">
          {suggestionsQuery.data.length === 0 && (
            <span className="tag-picker__empty">No existing match — add it below instead.</span>
          )}
          {suggestionsQuery.data.map((tag) => (
            <button
              key={tag.id}
              type="button"
              className={`tag-suggestion ${selected.some((t) => t.id === tag.id) ? "tag-suggestion--selected" : ""}`}
              onClick={() => toggle(tag)}
            >
              {tag.label}
            </button>
          ))}
        </div>
      )}

      {selected.length > 0 && (
        <div className="selected-tags">
          {selected.map((tag) => (
            <button key={tag.id} type="button" className="selected-tag" onClick={() => toggle(tag)}>
              {tag.label} ✕
            </button>
          ))}
        </div>
      )}

      <label className="field">
        <span>Don't see it above? Add more, comma-separated — new ones are created automatically</span>
        <input
          type="text"
          value={freeformValue}
          onChange={(e) => onFreeformChange(e.target.value)}
          placeholder="e.g. Underwater Lighting, Custom Camera Rig"
        />
      </label>

      {resolutions.length > 0 && (
        <ul className="tag-resolution-list">
          {resolutions.map((r) => (
            <li key={r.term} className={r.match ? "tag-resolution--existing" : "tag-resolution--new"}>
              {r.match ? (
                <>
                  "{r.term}" already exists as <strong>{r.match.label}</strong> — that one will be used, not a
                  duplicate.
                </>
              ) : (
                <>"{r.term}" will be created as a new tag.</>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
