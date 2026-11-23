import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";

export function ProjectsPage() {
  const [q, setQ] = useState("");

  const projectsQuery = useQuery({
    queryKey: ["projects", q],
    queryFn: () => api.projects.list({ q: q || undefined }),
  });

  return (
    <div className="projects-page">
      <h2>Projects</h2>
      <label className="field">
        <span>Search</span>
        <input
          type="text"
          placeholder="e.g. commercial, real estate..."
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </label>

      {projectsQuery.isLoading && <p>Loading…</p>}
      {projectsQuery.data && projectsQuery.data.length === 0 && <p>No projects found.</p>}
      <ul className="project-list">
        {projectsQuery.data?.map((project) => (
          <li key={project.id}>
            <Link to={`/projects/${project.id}`} className="project-list__item">
              <h3>{project.name}</h3>
              <span className={`status-chip status-chip--${project.status}`}>{project.status}</span>
              {project.location_label && <p>{project.location_label}</p>}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
