import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Tag } from "../api/types";

type Toast = { id: number; kind: "success" | "error"; message: string };

let toastSeq = 0;

function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  function push(kind: Toast["kind"], message: string) {
    const id = ++toastSeq;
    setToasts((prev) => [...prev, { id, kind, message }]);
    setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), 4000);
  }
  return { toasts, push };
}

function ToastStack({ toasts }: { toasts: Toast[] }) {
  if (toasts.length === 0) return null;
  return (
    <div className="toast-stack">
      {toasts.map((t) => (
        <div key={t.id} className={`toast toast--${t.kind}`}>
          {t.message}
        </div>
      ))}
    </div>
  );
}

function AddTagForm({ onToast }: { onToast: (kind: Toast["kind"], message: string) => void }) {
  const queryClient = useQueryClient();
  const [tagType, setTagType] = useState<"skill" | "equipment" | "role">("skill");
  const [label, setLabel] = useState("");
  const [category, setCategory] = useState("");
  const [aliases, setAliases] = useState("");

  // Duplicate-prevention: show what already exists for this type as the
  // admin types a label, before they submit a possible duplicate.
  const matchesQuery = useQuery({
    queryKey: ["tags", tagType, label],
    queryFn: () => api.tags.list({ tag_type: tagType, q: label }),
    enabled: label.trim().length > 1,
  });
  const exactMatch = matchesQuery.data?.find((t) => t.label.toLowerCase() === label.trim().toLowerCase());

  const createTag = useMutation({
    mutationFn: () =>
      api.tags.create({
        tag_type: tagType,
        label,
        category: category || undefined,
        aliases: aliases
          .split(",")
          .map((a) => a.trim())
          .filter(Boolean),
      }),
    onSuccess: (tag) => {
      onToast("success", `Saved "${tag.label}".`);
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      setLabel("");
      setCategory("");
      setAliases("");
    },
    onError: (err) => onToast("error", `Couldn't create tag: ${(err as Error).message}`),
  });

  return (
    <section className="panel">
      <h3>Add a skill, equipment, or role tag</h3>
      <p className="panel__hint">
        For a new vocabulary entry that isn't covered yet. Submitting an exact match of an existing tag (same type,
        same label) reuses that tag instead of creating a duplicate.
      </p>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          createTag.mutate();
        }}
      >
        <label className="field">
          <span>Type</span>
          <select value={tagType} onChange={(e) => setTagType(e.target.value as typeof tagType)}>
            <option value="skill">Skill</option>
            <option value="equipment">Equipment</option>
            <option value="role">Role</option>
          </select>
        </label>

        <label className="field">
          <span>Label</span>
          <input
            type="text"
            placeholder="e.g. Underwater Lighting Technician"
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            required
          />
        </label>

        {label.trim().length > 1 && matchesQuery.data && matchesQuery.data.length > 0 && (
          <div className="tag-duplicate-hint">
            <span className="tag-duplicate-hint__label">
              {exactMatch ? "This already exists:" : `Similar ${tagType} tags already exist:`}
            </span>
            <div className="tag-suggestions">
              {matchesQuery.data.map((tag: Tag) => (
                <span key={tag.id} className="tag-suggestion tag-suggestion--readonly">
                  {tag.label}
                </span>
              ))}
            </div>
          </div>
        )}

        <label className="field">
          <span>Category</span>
          <input
            type="text"
            placeholder="e.g. Grip & Electric"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Aliases (comma-separated)</span>
          <input type="text" placeholder="e.g. UWLT" value={aliases} onChange={(e) => setAliases(e.target.value)} />
        </label>

        <button type="submit" className="btn btn--primary" disabled={!label || createTag.isPending}>
          {createTag.isPending ? "Saving…" : exactMatch ? "Use existing tag" : "Add tag"}
        </button>
      </form>
    </section>
  );
}

function AddProjectForm({ onToast }: { onToast: (kind: Toast["kind"], message: string) => void }) {
  const queryClient = useQueryClient();
  const [name, setName] = useState("");
  const [projectType, setProjectType] = useState("");
  const [description, setDescription] = useState("");
  const [locationLabel, setLocationLabel] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  const createProject = useMutation({
    mutationFn: () =>
      api.projects.create({
        name,
        project_type: projectType || undefined,
        description: description || undefined,
        location_label: locationLabel || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
      }),
    onSuccess: (project) => {
      onToast("success", `Created project "${project.name}".`);
      queryClient.invalidateQueries({ queryKey: ["projects"] });
      setName("");
      setProjectType("");
      setDescription("");
      setLocationLabel("");
      setStartDate("");
      setEndDate("");
    },
    onError: (err) => onToast("error", `Couldn't create project: ${(err as Error).message}`),
  });

  return (
    <section className="panel">
      <h3>Add a project</h3>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          createProject.mutate();
        }}
      >
        <label className="field">
          <span>Name</span>
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} required />
        </label>

        <label className="field">
          <span>Project type</span>
          <input
            type="text"
            placeholder="e.g. Commercial, Documentary, Live Event"
            value={projectType}
            onChange={(e) => setProjectType(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Description</span>
          <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} />
        </label>

        <label className="field">
          <span>Location</span>
          <input type="text" value={locationLabel} onChange={(e) => setLocationLabel(e.target.value)} />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Start date</span>
            <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </label>
          <label className="field">
            <span>End date</span>
            <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </label>
        </div>

        <button type="submit" className="btn btn--primary" disabled={!name || createProject.isPending}>
          {createProject.isPending ? "Creating…" : "Add project"}
        </button>
      </form>
    </section>
  );
}

const TAG_TYPES = ["skill", "equipment", "role"] as const;

interface TagDraft {
  tagType: (typeof TAG_TYPES)[number];
  label: string;
  category: string;
  aliases: string;
}

function draftFromTag(tag: Tag): TagDraft {
  return {
    tagType: tag.tag_type,
    label: tag.label,
    category: tag.category ?? "",
    aliases: (tag.aliases ?? []).join(", "),
  };
}

function ManageTagsSection({ onToast }: { onToast: (kind: Toast["kind"], message: string) => void }) {
  const queryClient = useQueryClient();
  const [tagType, setTagType] = useState<"" | (typeof TAG_TYPES)[number]>("");
  const [q, setQ] = useState("");

  // Plain substring filtering client-side, not the shared /tags?q= fuzzy
  // search — that endpoint uses trigram similarity, which is tuned for
  // typo-tolerant discovery and misses short literal substrings (e.g.
  // searching "QA" won't fuzzy-match "QA Brand New Skill"). An admin
  // browsing/managing the vocabulary wants plain "contains", so fetch by
  // type and filter here instead.
  const tagsQuery = useQuery({
    queryKey: ["tags", "manage", tagType],
    queryFn: () => api.tags.list({ tag_type: tagType || undefined }),
  });

  const filteredTags = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return tagsQuery.data ?? [];
    return (tagsQuery.data ?? []).filter(
      (tag) =>
        tag.label.toLowerCase().includes(needle) ||
        (tag.category ?? "").toLowerCase().includes(needle) ||
        (tag.aliases ?? []).some((a) => a.toLowerCase().includes(needle)),
    );
  }, [tagsQuery.data, q]);

  // Independent of the `tagType` filter above (which may be scoped to one
  // type or empty) — this always fetches every active tag, across all
  // types, so the category type-ahead in the row editor has the complete
  // list to search no matter what the admin's current filter is set to.
  const allTagsForCategoriesQuery = useQuery({
    queryKey: ["tags", "manage", "all-for-categories"],
    queryFn: () => api.tags.list({}),
  });

  const categoriesByType = useMemo(() => {
    const map = new Map<string, Set<string>>();
    for (const t of allTagsForCategoriesQuery.data ?? []) {
      if (!t.category) continue;
      if (!map.has(t.tag_type)) map.set(t.tag_type, new Set());
      map.get(t.tag_type)!.add(t.category);
    }
    return map;
  }, [allTagsForCategoriesQuery.data]);

  const [confirmingId, setConfirmingId] = useState<string | null>(null);

  const deactivate = useMutation({
    mutationFn: (tagId: string) => api.tags.deactivate(tagId),
    onSuccess: (_void, tagId) => {
      const tag = tagsQuery.data?.find((t) => t.id === tagId);
      onToast("success", `Deactivated "${tag?.label ?? "tag"}".`);
      setConfirmingId(null);
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    onError: (err) => onToast("error", `Couldn't deactivate: ${(err as Error).message}`),
  });

  const [editingId, setEditingId] = useState<string | null>(null);
  const [editDraft, setEditDraft] = useState<TagDraft | null>(null);

  function startEdit(tag: Tag) {
    setConfirmingId(null);
    setEditingId(tag.id);
    setEditDraft(draftFromTag(tag));
  }

  function cancelEdit() {
    setEditingId(null);
    setEditDraft(null);
  }

  const updateTag = useMutation({
    mutationFn: ({ id, draft }: { id: string; draft: TagDraft }) =>
      api.tags.update(id, {
        tag_type: draft.tagType,
        label: draft.label.trim(),
        category: draft.category.trim() || null,
        aliases: draft.aliases
          .split(",")
          .map((a) => a.trim())
          .filter(Boolean),
      }),
    onSuccess: (tag) => {
      onToast("success", `Saved "${tag.label}".`);
      cancelEdit();
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    onError: (err) => onToast("error", `Couldn't save: ${(err as Error).message}`),
  });

  const grouped = useMemo(() => {
    const groups = new Map<string, Tag[]>();
    for (const tag of filteredTags) {
      const key = tag.category ?? "Uncategorized";
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key)!.push(tag);
    }
    return [...groups.entries()].sort(([a], [b]) => a.localeCompare(b));
  }, [filteredTags]);

  return (
    <section className="panel admin-page__manage-tags">
      <h3>Manage tags</h3>
      <p className="panel__hint">
        Deactivate tags that shouldn't be in use — this is a soft delete (the tag record stays, it just stops
        appearing in search, type-ahead, and the picker on the submission form). There's no "reactivate" yet.
      </p>
      <div className="form-row">
        <label className="field">
          <span>Type</span>
          <select value={tagType} onChange={(e) => setTagType(e.target.value as typeof tagType)}>
            <option value="">All</option>
            <option value="skill">Skill</option>
            <option value="equipment">Equipment</option>
            <option value="role">Role</option>
          </select>
        </label>
        <label className="field">
          <span>Search</span>
          <input type="text" placeholder="Filter by label or alias…" value={q} onChange={(e) => setQ(e.target.value)} />
        </label>
      </div>

      {tagsQuery.isLoading && <p>Loading…</p>}
      {tagsQuery.data && filteredTags.length === 0 && <p>No matching active tags.</p>}

      {editDraft && (
        <datalist id="existing-categories">
          {[...(categoriesByType.get(editDraft.tagType) ?? [])].sort().map((category) => (
            <option key={category} value={category} />
          ))}
        </datalist>
      )}

      <div className="manage-tags-list">
        {grouped.map(([category, tags]) => (
          <div key={category} className="manage-tags-group">
            <h4>{category}</h4>
            <ul className="plain-list">
              {tags.map((tag) =>
                editingId === tag.id && editDraft ? (
                  <li key={tag.id} className="manage-tags-row manage-tags-row--editing">
                    <select
                      className="manage-tags-row__edit-field"
                      value={editDraft.tagType}
                      onChange={(e) => setEditDraft({ ...editDraft, tagType: e.target.value as TagDraft["tagType"] })}
                    >
                      <option value="skill">Skill</option>
                      <option value="equipment">Equipment</option>
                      <option value="role">Role</option>
                    </select>
                    <input
                      type="text"
                      className="manage-tags-row__edit-field"
                      placeholder="Label"
                      value={editDraft.label}
                      onChange={(e) => setEditDraft({ ...editDraft, label: e.target.value })}
                    />
                    <input
                      type="text"
                      className="manage-tags-row__edit-field"
                      placeholder="Category"
                      value={editDraft.category}
                      list="existing-categories"
                      onChange={(e) => setEditDraft({ ...editDraft, category: e.target.value })}
                    />
                    <input
                      type="text"
                      className="manage-tags-row__edit-field manage-tags-row__edit-field--wide"
                      placeholder="Aliases (comma-separated)"
                      value={editDraft.aliases}
                      onChange={(e) => setEditDraft({ ...editDraft, aliases: e.target.value })}
                    />
                    <button
                      type="button"
                      className="btn btn--primary btn--small"
                      disabled={!editDraft.label.trim() || updateTag.isPending}
                      onClick={() => updateTag.mutate({ id: tag.id, draft: editDraft })}
                    >
                      {updateTag.isPending ? "Saving…" : "Save"}
                    </button>
                    <button type="button" className="btn btn--secondary btn--small" onClick={cancelEdit}>
                      Cancel
                    </button>
                  </li>
                ) : (
                  <li key={tag.id} className="manage-tags-row">
                    <span className={`tag-chip tag-chip--${tag.tag_type}`}>{tag.label}</span>
                    {tag.aliases && tag.aliases.length > 0 && (
                      <span className="manage-tags-row__aliases">aka {tag.aliases.join(", ")}</span>
                    )}
                    <span className="manage-tags-row__actions">
                    {confirmingId === tag.id ? (
                      <span className="manage-tags-row__confirm">
                        <span>Deactivate?</span>
                        <button
                          type="button"
                          className="btn btn--primary btn--small"
                          onClick={() => deactivate.mutate(tag.id)}
                          disabled={deactivate.isPending}
                        >
                          {deactivate.isPending ? "…" : "Yes"}
                        </button>
                        <button
                          type="button"
                          className="btn btn--secondary btn--small"
                          onClick={() => setConfirmingId(null)}
                        >
                          Cancel
                        </button>
                      </span>
                    ) : (
                      <>
                        <button type="button" className="btn btn--secondary btn--small" onClick={() => startEdit(tag)}>
                          Edit
                        </button>
                        <button
                          type="button"
                          className="btn btn--secondary btn--small"
                          onClick={() => setConfirmingId(tag.id)}
                        >
                          Deactivate
                        </button>
                      </>
                    )}
                    </span>
                  </li>
                ),
              )}
            </ul>
          </div>
        ))}
      </div>
    </section>
  );
}

export function AdminPage() {
  const { toasts, push } = useToasts();

  return (
    <div className="admin-page">
      <h2>Admin</h2>
      <p className="panel__hint">
        Manage the controlled vocabulary and projects. To add a person or business, use{" "}
        <Link to="/join">List yourself</Link> — the same form the public uses.
      </p>
      <div className="admin-page__grid">
        <AddTagForm onToast={push} />
        <AddProjectForm onToast={push} />
      </div>
      <ManageTagsSection onToast={push} />
      <ToastStack toasts={toasts} />
    </div>
  );
}
