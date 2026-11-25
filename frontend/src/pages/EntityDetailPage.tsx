import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import { TagChip } from "../components/TagChip";
import { TagPicker } from "../components/TagPicker";
import type { Tag } from "../api/types";

const TAG_SECTIONS: { tagType: Tag["tag_type"]; heading: string }[] = [
  { tagType: "role", heading: "Roles" },
  { tagType: "skill", heading: "Skills" },
  { tagType: "equipment", heading: "Equipment" },
];

export function EntityDetailPage() {
  const { entityId } = useParams<{ entityId: string }>();
  const queryClient = useQueryClient();

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

  const [isEditing, setIsEditing] = useState(false);
  const [draftName, setDraftName] = useState("");
  const [draftHeadline, setDraftHeadline] = useState("");
  const [draftBio, setDraftBio] = useState("");
  const [draftLocation, setDraftLocation] = useState("");
  const [draftEmail, setDraftEmail] = useState("");
  const [draftPhone, setDraftPhone] = useState("");
  const [draftWebsite, setDraftWebsite] = useState("");
  const [draftFreeTextSkills, setDraftFreeTextSkills] = useState("");
  const [draftRoleTags, setDraftRoleTags] = useState<Tag[]>([]);
  const [draftRoleFreeform, setDraftRoleFreeform] = useState("");
  const [draftSkillTags, setDraftSkillTags] = useState<Tag[]>([]);
  const [draftSkillFreeform, setDraftSkillFreeform] = useState("");
  const [draftEquipmentTags, setDraftEquipmentTags] = useState<Tag[]>([]);
  const [draftEquipmentFreeform, setDraftEquipmentFreeform] = useState("");
  const [saveError, setSaveError] = useState<string | null>(null);

  const saveEdit = useMutation({
    mutationFn: async () => {
      const current = entityQuery.data!;
      const contact: Record<string, string> = { ...(current.contact as Record<string, string>) };
      if (draftEmail.trim()) contact.email = draftEmail.trim();
      else delete contact.email;
      if (draftPhone.trim()) contact.phone = draftPhone.trim();
      else delete contact.phone;
      if (draftWebsite.trim()) contact.website = draftWebsite.trim();
      else delete contact.website;

      await api.entities.update(current.id, {
        name: draftName.trim(),
        headline: draftHeadline.trim() || null,
        bio: draftBio.trim() || null,
        location_label: draftLocation.trim() || null,
        contact,
        free_text_skills: draftFreeTextSkills
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
      });

      const groups: Array<{ tagType: Tag["tag_type"]; selected: Tag[]; freeform: string }> = [
        { tagType: "role", selected: draftRoleTags, freeform: draftRoleFreeform },
        { tagType: "skill", selected: draftSkillTags, freeform: draftSkillFreeform },
        { tagType: "equipment", selected: draftEquipmentTags, freeform: draftEquipmentFreeform },
      ];

      for (const group of groups) {
        const ids = new Set(group.selected.map((t) => t.id));
        const newTerms = group.freeform
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean);
        for (const term of newTerms) {
          // Idempotent on the backend: an exact (case-insensitive) match
          // returns the existing tag instead of creating a duplicate.
          const tag = await api.tags.create({ tag_type: group.tagType, label: term });
          ids.add(tag.id);
        }

        const originalIds = new Set(current.tags.filter((t) => t.tag_type === group.tagType).map((t) => t.id));
        for (const id of ids) {
          if (!originalIds.has(id)) await api.entities.addTag(current.id, id);
        }
        for (const id of originalIds) {
          if (!ids.has(id)) await api.entities.removeTag(current.id, id);
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["entity", entityId] });
      setIsEditing(false);
    },
    onError: (err) => setSaveError((err as Error).message),
  });

  if (entityQuery.isLoading) return <p>Loading…</p>;
  if (entityQuery.isError || !entityQuery.data) return <p className="field-error">Entity not found.</p>;

  const entity = entityQuery.data;

  function startEdit() {
    setSaveError(null);
    setDraftName(entity.name);
    setDraftHeadline(entity.headline ?? "");
    setDraftBio(entity.bio ?? "");
    setDraftLocation(entity.location_label ?? "");
    setDraftEmail(String(entity.contact.email ?? ""));
    setDraftPhone(String(entity.contact.phone ?? ""));
    setDraftWebsite(String(entity.contact.website ?? ""));
    setDraftFreeTextSkills(entity.free_text_skills.join(", "));
    setDraftRoleTags(entity.tags.filter((t) => t.tag_type === "role"));
    setDraftRoleFreeform("");
    setDraftSkillTags(entity.tags.filter((t) => t.tag_type === "skill"));
    setDraftSkillFreeform("");
    setDraftEquipmentTags(entity.tags.filter((t) => t.tag_type === "equipment"));
    setDraftEquipmentFreeform("");
    setIsEditing(true);
  }

  if (isEditing) {
    return (
      <div className="entity-detail">
        <Link to="/" className="back-link">
          ← Back to search
        </Link>
        <h1>Edit {entity.name}</h1>

        <form
          className="panel"
          onSubmit={(e) => {
            e.preventDefault();
            setSaveError(null);
            saveEdit.mutate();
          }}
        >
          <label className="field">
            <span>Name</span>
            <input type="text" value={draftName} onChange={(e) => setDraftName(e.target.value)} required />
          </label>

          <label className="field">
            <span>Headline</span>
            <input type="text" value={draftHeadline} onChange={(e) => setDraftHeadline(e.target.value)} />
          </label>

          <label className="field">
            <span>Bio</span>
            <textarea rows={3} value={draftBio} onChange={(e) => setDraftBio(e.target.value)} />
          </label>

          <div className="form-row">
            <label className="field">
              <span>Email</span>
              <input type="text" value={draftEmail} onChange={(e) => setDraftEmail(e.target.value)} />
            </label>
            <label className="field">
              <span>Phone</span>
              <input type="text" value={draftPhone} onChange={(e) => setDraftPhone(e.target.value)} />
            </label>
          </div>

          <label className="field">
            <span>Website</span>
            <input type="text" value={draftWebsite} onChange={(e) => setDraftWebsite(e.target.value)} />
          </label>

          <label className="field">
            <span>Location</span>
            <input type="text" value={draftLocation} onChange={(e) => setDraftLocation(e.target.value)} />
          </label>

          <label className="field">
            <span>Also lists (comma-separated, free text)</span>
            <input
              type="text"
              value={draftFreeTextSkills}
              onChange={(e) => setDraftFreeTextSkills(e.target.value)}
            />
          </label>

          <h3>Roles</h3>
          <TagPicker
            tagType="role"
            label="Roles"
            selected={draftRoleTags}
            onSelectedChange={setDraftRoleTags}
            freeformValue={draftRoleFreeform}
            onFreeformChange={setDraftRoleFreeform}
          />

          <h3>Skills</h3>
          <TagPicker
            tagType="skill"
            label="Skills"
            selected={draftSkillTags}
            onSelectedChange={setDraftSkillTags}
            freeformValue={draftSkillFreeform}
            onFreeformChange={setDraftSkillFreeform}
          />

          <h3>Equipment</h3>
          <TagPicker
            tagType="equipment"
            label="Equipment"
            selected={draftEquipmentTags}
            onSelectedChange={setDraftEquipmentTags}
            freeformValue={draftEquipmentFreeform}
            onFreeformChange={setDraftEquipmentFreeform}
          />

          {saveError && <p className="field-error">Couldn't save: {saveError}</p>}

          <div className="form-row">
            <button type="submit" className="btn btn--primary" disabled={!draftName.trim() || saveEdit.isPending}>
              {saveEdit.isPending ? "Saving…" : "Save changes"}
            </button>
            <button type="button" className="btn btn--secondary" onClick={() => setIsEditing(false)}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    );
  }

  return (
    <div className="entity-detail">
      <Link to="/" className="back-link">
        ← Back to search
      </Link>
      <div className="entity-detail__header-row">
        <h1>{entity.name}</h1>
        <button type="button" className="btn btn--secondary btn--small" onClick={startEdit}>
          Edit
        </button>
      </div>
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
