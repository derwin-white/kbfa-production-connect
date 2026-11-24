export interface EntityType {
  id: number;
  kind: "individual" | "business";
  code: string;
  label: string;
  description: string | null;
}

export interface Tag {
  id: string;
  tag_type: "skill" | "equipment" | "role";
  label: string;
  category: string | null;
  aliases?: string[];
}

export interface Entity {
  id: string;
  entity_type_id: number;
  name: string;
  headline: string | null;
  bio: string | null;
  contact: Record<string, unknown>;
  free_text_skills: string[];
  location_label: string | null;
  metadata: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface EntitySearchResult extends Entity {
  distance_miles: number | null;
  rank: number | null;
  tags: Tag[];
}

export interface ConnectedEntity {
  id: string;
  name: string;
  headline: string | null;
  connection_status: string;
}

export interface Project {
  id: string;
  owner_entity_id: string | null;
  name: string;
  description: string | null;
  project_type: string | null;
  status: string;
  location_label: string | null;
  start_date: string | null;
  end_date: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface ProjectMember {
  entity_id: string;
  entity_name: string;
  role: string | null;
  status: string;
}

export interface EntitySearchParams {
  q?: string;
  tag_ids?: string[];
  entity_type_code?: string;
  latitude?: number;
  longitude?: number;
  radius_miles?: number;
  limit?: number;
  offset?: number;
}

export interface EntityCreateInput {
  entity_type_id: number;
  name: string;
  headline?: string;
  bio?: string;
  contact?: Record<string, string>;
  free_text_skills?: string[];
  location_label?: string;
  latitude?: number;
  longitude?: number;
}

export interface TagCreateInput {
  tag_type: "skill" | "equipment" | "role";
  label: string;
  category?: string;
  aliases?: string[];
}

export interface ProjectCreateInput {
  name: string;
  description?: string;
  project_type?: string;
  status?: string;
  location_label?: string;
  start_date?: string;
  end_date?: string;
}

export interface ProjectMemberCreateInput {
  entity_id: string;
  role_tag_id?: string;
  role_free_text?: string;
}
