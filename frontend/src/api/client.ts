import type {
  ConnectedEntity,
  Entity,
  EntityCreateInput,
  EntitySearchParams,
  EntitySearchResult,
  EntityType,
  Project,
  ProjectCreateInput,
  ProjectMember,
  Tag,
  TagCreateInput,
} from "./types";

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://127.0.0.1:8000";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${BASE_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`${response.status} ${response.statusText}: ${detail}`);
  }
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

function buildQuery<T extends object>(params: T): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    if (Array.isArray(value)) {
      for (const item of value) search.append(key, String(item));
    } else {
      search.set(key, String(value));
    }
  }
  const qs = search.toString();
  return qs ? `?${qs}` : "";
}

export const api = {
  entityTypes: {
    list: () => request<EntityType[]>("/entity-types/"),
  },

  tags: {
    list: (params: { tag_type?: string; q?: string } = {}) =>
      request<Tag[]>(`/tags/${buildQuery(params)}`),
    create: (payload: TagCreateInput) =>
      request<Tag>("/tags/", { method: "POST", body: JSON.stringify(payload) }),
    deactivate: (tagId: string) => request<void>(`/tags/${tagId}`, { method: "DELETE" }),
  },

  entities: {
    search: (params: EntitySearchParams) =>
      request<EntitySearchResult[]>(`/entities/${buildQuery(params)}`),
    get: (id: string) => request<EntitySearchResult>(`/entities/${id}`),
    create: (payload: EntityCreateInput) =>
      request<Entity>("/entities/", { method: "POST", body: JSON.stringify(payload) }),
    addTag: (entityId: string, tagId: string) =>
      request<void>(`/entities/${entityId}/tags/${tagId}`, { method: "POST" }),
  },

  connections: {
    listForEntity: (entityId: string, status?: string) =>
      request<ConnectedEntity[]>(`/connections/entity/${entityId}${buildQuery({ status })}`),
    secondDegree: (entityId: string) =>
      request<ConnectedEntity[]>(`/connections/entity/${entityId}/second-degree`),
  },

  projects: {
    list: (params: { q?: string; status?: string } = {}) =>
      request<Project[]>(`/projects/${buildQuery(params)}`),
    get: (id: string) => request<Project>(`/projects/${id}`),
    members: (id: string) => request<ProjectMember[]>(`/projects/${id}/members`),
    create: (payload: ProjectCreateInput) =>
      request<Project>("/projects/", { method: "POST", body: JSON.stringify(payload) }),
  },
};

export type { ConnectedEntity, Entity, EntitySearchResult, EntityType, Project, ProjectMember, Tag };
