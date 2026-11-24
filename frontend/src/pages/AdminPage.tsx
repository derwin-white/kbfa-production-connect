import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { api } from "../api/client";

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

function AddEntityForm({ onToast }: { onToast: (kind: Toast["kind"], message: string) => void }) {
  const queryClient = useQueryClient();
  const [entityTypeId, setEntityTypeId] = useState("");
  const [name, setName] = useState("");
  const [headline, setHeadline] = useState("");
  const [bio, setBio] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [website, setWebsite] = useState("");
  const [locationLabel, setLocationLabel] = useState("");
  const [freeTextSkills, setFreeTextSkills] = useState("");
  const [tagQuery, setTagQuery] = useState("");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);

  const entityTypesQuery = useQuery({ queryKey: ["entity-types"], queryFn: () => api.entityTypes.list() });
  const tagSuggestionsQuery = useQuery({
    queryKey: ["tags", tagQuery],
    queryFn: () => api.tags.list({ q: tagQuery || undefined }),
    enabled: tagQuery.length > 0,
  });

  const createEntity = useMutation({
    mutationFn: async () => {
      const contact: Record<string, string> = {};
      if (email) contact.email = email;
      if (phone) contact.phone = phone;
      if (website) contact.website = website;

      const entity = await api.entities.create({
        entity_type_id: Number(entityTypeId),
        name,
        headline: headline || undefined,
        bio: bio || undefined,
        contact,
        free_text_skills: freeTextSkills
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
        location_label: locationLabel || undefined,
      });
      for (const tagId of selectedTagIds) {
        await api.entities.addTag(entity.id, tagId);
      }
      return entity;
    },
    onSuccess: (entity) => {
      onToast("success", `Created "${entity.name}".`);
      queryClient.invalidateQueries({ queryKey: ["entity-search"] });
      setEntityTypeId("");
      setName("");
      setHeadline("");
      setBio("");
      setEmail("");
      setPhone("");
      setWebsite("");
      setLocationLabel("");
      setFreeTextSkills("");
      setTagQuery("");
      setSelectedTagIds([]);
    },
    onError: (err) => onToast("error", `Couldn't create entity: ${(err as Error).message}`),
  });

  function toggleTag(tagId: string) {
    setSelectedTagIds((prev) => (prev.includes(tagId) ? prev.filter((id) => id !== tagId) : [...prev, tagId]));
  }

  const selectedTags = tagSuggestionsQuery.data?.filter((t) => selectedTagIds.includes(t.id)) ?? [];

  return (
    <section className="panel">
      <h3>Add a person or business</h3>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          createEntity.mutate();
        }}
      >
        <label className="field">
          <span>Type</span>
          <select value={entityTypeId} onChange={(e) => setEntityTypeId(e.target.value)} required>
            <option value="" disabled>
              Select a type…
            </option>
            {entityTypesQuery.data?.map((t) => (
              <option key={t.id} value={t.id}>
                {t.label}
              </option>
            ))}
          </select>
        </label>

        <label className="field">
          <span>Name</span>
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} required />
        </label>

        <label className="field">
          <span>Headline</span>
          <input
            type="text"
            placeholder="e.g. Freelance Gaffer, NY/NJ"
            value={headline}
            onChange={(e) => setHeadline(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Bio</span>
          <textarea rows={3} value={bio} onChange={(e) => setBio(e.target.value)} />
        </label>

        <div className="form-row">
          <label className="field">
            <span>Email</span>
            <input type="text" value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          <label className="field">
            <span>Phone</span>
            <input type="text" value={phone} onChange={(e) => setPhone(e.target.value)} />
          </label>
        </div>

        <label className="field">
          <span>Website</span>
          <input type="text" value={website} onChange={(e) => setWebsite(e.target.value)} />
        </label>

        <label className="field">
          <span>Location</span>
          <input
            type="text"
            placeholder="e.g. Brooklyn, NY"
            value={locationLabel}
            onChange={(e) => setLocationLabel(e.target.value)}
          />
        </label>

        <label className="field">
          <span>Free-text skills (comma-separated, for anything not in the tag list below)</span>
          <input type="text" value={freeTextSkills} onChange={(e) => setFreeTextSkills(e.target.value)} />
        </label>

        <label className="field">
          <span>Skills / equipment / roles</span>
          <input
            type="text"
            placeholder="Start typing to find a tag…"
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

        <button type="submit" className="btn btn--primary" disabled={!entityTypeId || !name || createEntity.isPending}>
          {createEntity.isPending ? "Creating…" : "Add entity"}
        </button>
      </form>
    </section>
  );
}

function AddTagForm({ onToast }: { onToast: (kind: Toast["kind"], message: string) => void }) {
  const queryClient = useQueryClient();
  const [tagType, setTagType] = useState<"skill" | "equipment" | "role">("skill");
  const [label, setLabel] = useState("");
  const [category, setCategory] = useState("");
  const [aliases, setAliases] = useState("");

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
      onToast("success", `Added tag "${tag.label}".`);
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
        For a new vocabulary entry that isn't covered yet — not for one-off skills specific to a single person (use
        their free-text skills field for that instead).
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
          <input
            type="text"
            placeholder="e.g. UWLT"
            value={aliases}
            onChange={(e) => setAliases(e.target.value)}
          />
        </label>

        <button type="submit" className="btn btn--primary" disabled={!label || createTag.isPending}>
          {createTag.isPending ? "Adding…" : "Add tag"}
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

export function AdminPage() {
  const { toasts, push } = useToasts();

  return (
    <div className="admin-page">
      <h2>Admin — enter data</h2>
      <p className="panel__hint">
        Add entities, controlled-vocabulary tags, and projects directly. Everything here is saved immediately to the
        live database — there's no draft/review step yet.
      </p>
      <div className="admin-page__grid">
        <AddEntityForm onToast={push} />
        <AddTagForm onToast={push} />
        <AddProjectForm onToast={push} />
      </div>
      <ToastStack toasts={toasts} />
    </div>
  );
}
