import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";
import type { EntitySearchResult, Tag } from "../api/types";

function JoinProjectSection({ projectId }: { projectId: string }) {
  const queryClient = useQueryClient();
  const [entityQuery, setEntityQuery] = useState("");
  const [selectedEntity, setSelectedEntity] = useState<EntitySearchResult | null>(null);
  const [roleQuery, setRoleQuery] = useState("");
  const [selectedRole, setSelectedRole] = useState<Tag | null>(null);
  const [customRole, setCustomRole] = useState("");
  const [confirmation, setConfirmation] = useState<string | null>(null);

  const entitySuggestionsQuery = useQuery({
    queryKey: ["entity-search", "join-picker", entityQuery],
    queryFn: () => api.entities.search({ q: entityQuery, limit: 8 }),
    enabled: entityQuery.length > 1 && !selectedEntity,
  });

  const roleSuggestionsQuery = useQuery({
    queryKey: ["tags", "role", "join-picker", roleQuery],
    queryFn: () => api.tags.list({ tag_type: "role", q: roleQuery }),
    enabled: roleQuery.length > 0 && !selectedRole,
  });

  const join = useMutation({
    mutationFn: () =>
      api.projects.addMember(projectId, {
        entity_id: selectedEntity!.id,
        role_tag_id: selectedRole?.id,
        role_free_text: selectedRole ? undefined : customRole.trim() || undefined,
      }),
    onSuccess: (member) => {
      setConfirmation(`You're on the roster as ${member.role ?? "a member"}.`);
      queryClient.invalidateQueries({ queryKey: ["project-members", projectId] });
    },
  });

  if (confirmation) {
    return (
      <section className="panel join-project">
        <h3>Joined!</h3>
        <p>{confirmation}</p>
      </section>
    );
  }

  return (
    <section className="panel join-project">
      <h3>Link yourself to this project</h3>
      <p className="panel__hint">
        Already in the system? Find your profile below and add yourself to the roster with your role.
      </p>

      {!selectedEntity ? (
        <>
          <label className="field">
            <span>Find yourself</span>
            <input
              type="text"
              placeholder="Search your name…"
              value={entityQuery}
              onChange={(e) => setEntityQuery(e.target.value)}
            />
          </label>
          {entityQuery.length > 1 && entitySuggestionsQuery.data && (
            <div className="tag-suggestions">
              {entitySuggestionsQuery.data.length === 0 && (
                <span className="tag-picker__empty">
                  No match — <Link to="/join">list yourself</Link> first.
                </span>
              )}
              {entitySuggestionsQuery.data.map((entity) => (
                <button
                  key={entity.id}
                  type="button"
                  className="tag-suggestion"
                  onClick={() => {
                    setSelectedEntity(entity);
                    setEntityQuery("");
                  }}
                >
                  {entity.name}
                </button>
              ))}
            </div>
          )}
        </>
      ) : (
        <>
          <p className="join-project__identity">
            You are: <strong>{selectedEntity.name}</strong>{" "}
            <button type="button" className="btn btn--secondary btn--small" onClick={() => setSelectedEntity(null)}>
              Not you?
            </button>
          </p>

          {!selectedRole ? (
            <>
              <label className="field">
                <span>Your role on this project</span>
                <input
                  type="text"
                  placeholder="Search for your role…"
                  value={roleQuery}
                  onChange={(e) => setRoleQuery(e.target.value)}
                />
              </label>
              {roleQuery.length > 0 && roleSuggestionsQuery.data && (
                <div className="tag-suggestions">
                  {roleSuggestionsQuery.data.map((tag) => (
                    <button
                      key={tag.id}
                      type="button"
                      className="tag-suggestion"
                      onClick={() => {
                        setSelectedRole(tag);
                        setRoleQuery("");
                      }}
                    >
                      {tag.label}
                    </button>
                  ))}
                </div>
              )}
              <label className="field">
                <span>Don't see your role? Describe it</span>
                <input
                  type="text"
                  placeholder="e.g. Craft Services Lead"
                  value={customRole}
                  onChange={(e) => setCustomRole(e.target.value)}
                />
              </label>
            </>
          ) : (
            <p className="join-project__identity">
              Role: <strong>{selectedRole.label}</strong>{" "}
              <button type="button" className="btn btn--secondary btn--small" onClick={() => setSelectedRole(null)}>
                Change
              </button>
            </p>
          )}

          {join.isError && <p className="field-error">Couldn't join: {(join.error as Error).message}</p>}

          <button
            type="button"
            className="btn btn--primary"
            disabled={(!selectedRole && !customRole.trim()) || join.isPending}
            onClick={() => join.mutate()}
          >
            {join.isPending ? "Joining…" : "Add me to this project"}
          </button>
        </>
      )}
    </section>
  );
}

export function ProjectDetailPage() {
  const { projectId } = useParams<{ projectId: string }>();

  const projectQuery = useQuery({
    queryKey: ["project", projectId],
    queryFn: () => api.projects.get(projectId!),
    enabled: Boolean(projectId),
  });

  const membersQuery = useQuery({
    queryKey: ["project-members", projectId],
    queryFn: () => api.projects.members(projectId!),
    enabled: Boolean(projectId),
  });

  if (projectQuery.isLoading) return <p>Loading…</p>;
  if (projectQuery.isError || !projectQuery.data) return <p className="field-error">Project not found.</p>;

  const project = projectQuery.data;

  return (
    <div className="entity-detail">
      <Link to="/projects" className="back-link">
        ← Back to projects
      </Link>
      <h1>{project.name}</h1>
      <span className={`status-chip status-chip--${project.status}`}>{project.status}</span>
      {project.project_type && <p className="entity-detail__headline">{project.project_type}</p>}
      {project.location_label && <p className="entity-detail__location">📍 {project.location_label}</p>}
      {project.description && <p className="entity-detail__bio">{project.description}</p>}

      <section>
        <h2>Roster</h2>
        {membersQuery.data && membersQuery.data.length > 0 ? (
          <ul className="plain-list">
            {membersQuery.data.map((member) => (
              <li key={member.entity_id}>
                <Link to={`/entities/${member.entity_id}`}>{member.entity_name}</Link>
                {member.role ? ` — ${member.role}` : ""}
              </li>
            ))}
          </ul>
        ) : (
          <p>No members yet.</p>
        )}
      </section>

      <section>{projectId && <JoinProjectSection projectId={projectId} />}</section>
    </div>
  );
}
