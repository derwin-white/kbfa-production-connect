import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { api } from "../api/client";

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
    </div>
  );
}
