import { useMutation, useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { api } from "../api/client";
import { TagPicker } from "../components/TagPicker";
import type { Tag } from "../api/types";

/** Tags created from freeform (not-found) entries on this public form are
 * tagged with this category so an admin can spot and review them later,
 * separately from the curated vocabulary. */
const USER_SUBMITTED_CATEGORY = "User Submitted";

export function JoinPage() {
  const [entityTypeId, setEntityTypeId] = useState("");
  const [name, setName] = useState("");
  const [headline, setHeadline] = useState("");
  const [bio, setBio] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [website, setWebsite] = useState("");
  const [locationLabel, setLocationLabel] = useState("");

  const [skillTags, setSkillTags] = useState<Tag[]>([]);
  const [skillFreeform, setSkillFreeform] = useState("");
  const [equipmentTags, setEquipmentTags] = useState<Tag[]>([]);
  const [equipmentFreeform, setEquipmentFreeform] = useState("");
  const [roleTags, setRoleTags] = useState<Tag[]>([]);
  const [roleFreeform, setRoleFreeform] = useState("");

  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const entityTypesQuery = useQuery({ queryKey: ["entity-types"], queryFn: () => api.entityTypes.list() });

  const submit = useMutation({
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
        location_label: locationLabel || undefined,
      });

      const groups: Array<{ tagType: "skill" | "equipment" | "role"; selected: Tag[]; freeform: string }> = [
        { tagType: "skill", selected: skillTags, freeform: skillFreeform },
        { tagType: "equipment", selected: equipmentTags, freeform: equipmentFreeform },
        { tagType: "role", selected: roleTags, freeform: roleFreeform },
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
          const tag = await api.tags.create({ tag_type: group.tagType, label: term, category: USER_SUBMITTED_CATEGORY });
          ids.add(tag.id);
        }
        for (const tagId of ids) {
          await api.entities.addTag(entity.id, tagId);
        }
      }

      return entity;
    },
    onSuccess: () => setSubmitted(true),
    onError: (err) => setError((err as Error).message),
  });

  if (submitted) {
    return (
      <div className="join-page">
        <div className="join-page__hero">
          <h2>You're listed!</h2>
          <p>Thanks — your profile is live and searchable. We'll be in touch if a production is a good match.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="join-page">
      <div className="join-page__hero">
        <h2>List yourself or your business</h2>
        <p>Tell production leads what you do, what you've got, and where to find you.</p>
      </div>

      <form
        className="panel join-page__form"
        onSubmit={(e) => {
          e.preventDefault();
          setError(null);
          submit.mutate();
        }}
      >
        <label className="field">
          <span>I am a…</span>
          <select value={entityTypeId} onChange={(e) => setEntityTypeId(e.target.value)} required>
            <option value="" disabled>
              Select one…
            </option>
            {entityTypesQuery.data?.map((t) => (
              <option key={t.id} value={t.id}>
                {t.label}
              </option>
            ))}
          </select>
        </label>

        <label className="field">
          <span>Name {entityTypeId && entityTypesQuery.data?.find((t) => String(t.id) === entityTypeId)?.kind === "business" ? "(business)" : "(your name)"}</span>
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
          <span>About you</span>
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

        <h3>Roles</h3>
        <TagPicker
          tagType="role"
          label="Roles"
          selected={roleTags}
          onSelectedChange={setRoleTags}
          freeformValue={roleFreeform}
          onFreeformChange={setRoleFreeform}
        />

        <h3>Skills</h3>
        <TagPicker
          tagType="skill"
          label="Skills"
          selected={skillTags}
          onSelectedChange={setSkillTags}
          freeformValue={skillFreeform}
          onFreeformChange={setSkillFreeform}
        />

        <h3>Equipment</h3>
        <TagPicker
          tagType="equipment"
          label="Equipment"
          selected={equipmentTags}
          onSelectedChange={setEquipmentTags}
          freeformValue={equipmentFreeform}
          onFreeformChange={setEquipmentFreeform}
        />

        {error && <p className="field-error">Couldn't submit: {error}</p>}

        <button type="submit" className="btn btn--primary" disabled={!entityTypeId || !name || submit.isPending}>
          {submit.isPending ? "Submitting…" : "List me"}
        </button>
      </form>
    </div>
  );
}
