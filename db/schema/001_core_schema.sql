-- KBFA Production Connect — core schema
-- Target: Aurora PostgreSQL (dev-prototyped here against local Postgres 18 + PostGIS 3.7)
--
-- Design notes:
--   * Skills/equipment/roles use a HYBRID taxonomy: a curated `tags` table
--     (controlled vocabulary) joined via `entity_tags`, PLUS a free-text
--     overflow array directly on `entities` for anything not in the
--     controlled list yet. New free-text values get periodically reviewed
--     and promoted into `tags`.
--   * Full-text search uses generated `tsvector` columns (name/bio/free-text
--     skills) with GIN indexes, `pg_trgm` for fuzzy/typo-tolerant matching
--     on names and tag labels, and PostGIS `geography(Point,4326)` for
--     location/proximity search.
--   * `connections` is a single undirected-pair edge table (LinkedIn-style
--     mutual connection), not a directed follow graph.

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- to_tsvector(regconfig, text) is STABLE in stock Postgres (the search config
-- could in principle change), which blocks it from a GENERATED column
-- (requires IMMUTABLE). Wrapping it with a fixed 'english' config is the
-- standard, documented workaround: safe because the config never varies here.
CREATE OR REPLACE FUNCTION immutable_english_tsvector(text)
RETURNS tsvector
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$ SELECT to_tsvector('english', $1) $$;

-- array_to_string(text[], text) is itself STABLE (its separator-collation
-- handling can vary), so it hits the same GENERATED-column restriction;
-- same fixed-behavior wrapper workaround as above.
CREATE OR REPLACE FUNCTION immutable_array_to_string(text[], text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$ SELECT array_to_string($1, $2) $$;

-- ---------------------------------------------------------------------------
-- entity_types: coarse classification of an entity (individual vs business,
-- plus a sub-category) — its own lookup table so new categories can be added
-- without a migration touching `entities` itself.
-- ---------------------------------------------------------------------------
CREATE TABLE entity_types (
    id          SMALLINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    kind        TEXT NOT NULL CHECK (kind IN ('individual', 'business')),
    code        TEXT NOT NULL UNIQUE,        -- e.g. 'crew', 'rental_house'
    label       TEXT NOT NULL,               -- e.g. 'Crew / Freelancer'
    description TEXT
);

INSERT INTO entity_types (kind, code, label, description) VALUES
    ('individual', 'crew',          'Crew / Freelancer',        'Individual production professional (camera, grip, sound, etc.)'),
    ('individual', 'talent',        'Talent',                   'On-camera talent, actor, host, model'),
    ('individual', 'creative',      'Creative / Director',      'Director, DP, showrunner, creative lead'),
    ('business',   'production_co', 'Production Company',       'Full-service production company'),
    ('business',   'rental_house',  'Equipment Rental House',   'Camera/grip/lighting rental business'),
    ('business',   'studio',        'Studio / Stage',           'Soundstage, studio space, or venue'),
    ('business',   'vendor',        'Vendor / Service',         'Catering, transportation, post house, other service vendor');

-- ---------------------------------------------------------------------------
-- tags: controlled vocabulary for skills, equipment, and project roles.
-- `aliases` backs synonym matching (e.g. "DP" -> "Director of Photography").
-- ---------------------------------------------------------------------------
CREATE TABLE tags (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_type  TEXT NOT NULL CHECK (tag_type IN ('skill', 'equipment', 'role')),
    label     TEXT NOT NULL,
    category  TEXT,                  -- e.g. 'Camera Department', 'Grip & Lighting'
    aliases   TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_tags_type_label ON tags (tag_type, lower(label));
CREATE INDEX ix_tags_category ON tags (tag_type, category);
CREATE INDEX ix_tags_label_trgm ON tags USING GIN (label gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- entities: individuals or businesses. One table, discriminated by
-- entity_type_id -> entity_types.kind.
-- ---------------------------------------------------------------------------
CREATE TABLE entities (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type_id   SMALLINT NOT NULL REFERENCES entity_types(id),
    name             TEXT NOT NULL,
    headline         TEXT,            -- short tagline, e.g. "Freelance Gaffer, NY/NJ"
    bio              TEXT,
    contact          JSONB NOT NULL DEFAULT '{}',   -- {email, phone, website, instagram, imdb, ...}
    free_text_skills TEXT[] NOT NULL DEFAULT '{}',  -- hybrid overflow bucket
    location_label   TEXT,            -- display string, e.g. "Brooklyn, NY"
    location         GEOGRAPHY(Point, 4326),
    metadata         JSONB NOT NULL DEFAULT '{}',   -- arbitrary flexible per-entity fields
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(immutable_english_tsvector(coalesce(name, '')), 'A') ||
        setweight(immutable_english_tsvector(coalesce(headline, '')), 'B') ||
        setweight(immutable_english_tsvector(coalesce(bio, '')), 'C') ||
        setweight(immutable_english_tsvector(coalesce(immutable_array_to_string(free_text_skills, ' '), '')), 'B')
    ) STORED
);

CREATE INDEX ix_entities_search_vector ON entities USING GIN (search_vector);
CREATE INDEX ix_entities_name_trgm ON entities USING GIN (name gin_trgm_ops);
CREATE INDEX ix_entities_free_text_skills ON entities USING GIN (free_text_skills);
CREATE INDEX ix_entities_metadata ON entities USING GIN (metadata jsonb_path_ops);
CREATE INDEX ix_entities_location ON entities USING GIST (location);
CREATE INDEX ix_entities_type ON entities (entity_type_id);

-- ---------------------------------------------------------------------------
-- entity_tags: many-to-many entity <-> controlled tag (skill/equipment/role)
-- ---------------------------------------------------------------------------
CREATE TABLE entity_tags (
    entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    tag_id    UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    added_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (entity_id, tag_id)
);

CREATE INDEX ix_entity_tags_tag ON entity_tags (tag_id);

-- ---------------------------------------------------------------------------
-- connections: mutual, undirected entity <-> entity edge (LinkedIn-style).
-- Stored as a directed request (requester/recipient) with a status, plus a
-- generated canonical-pair column so the SAME pair can't have two rows
-- regardless of who initiated.
-- ---------------------------------------------------------------------------
CREATE TABLE connections (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    recipient_entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    status             TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    note               TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at       TIMESTAMPTZ,
    pair_key UUID[] GENERATED ALWAYS AS (
        ARRAY[LEAST(requester_entity_id, recipient_entity_id),
              GREATEST(requester_entity_id, recipient_entity_id)]
    ) STORED,
    CHECK (requester_entity_id <> recipient_entity_id)
);

CREATE UNIQUE INDEX ux_connections_pair ON connections (pair_key);
CREATE INDEX ix_connections_requester ON connections (requester_entity_id);
CREATE INDEX ix_connections_recipient ON connections (recipient_entity_id);

-- ---------------------------------------------------------------------------
-- projects: a job/production that entities are (or could be) attached to.
-- ---------------------------------------------------------------------------
CREATE TABLE projects (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
    name            TEXT NOT NULL,
    description     TEXT,
    project_type    TEXT,             -- free text for now, e.g. 'Commercial', 'Documentary', 'Live Event'
    status          TEXT NOT NULL DEFAULT 'planning' CHECK (status IN ('planning', 'active', 'completed', 'cancelled')),
    location_label  TEXT,
    location        GEOGRAPHY(Point, 4326),
    start_date      DATE,
    end_date        DATE,
    metadata        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(immutable_english_tsvector(coalesce(name, '')), 'A') ||
        setweight(immutable_english_tsvector(coalesce(project_type, '')), 'B') ||
        setweight(immutable_english_tsvector(coalesce(description, '')), 'C')
    ) STORED
);

CREATE INDEX ix_projects_search_vector ON projects USING GIN (search_vector);
CREATE INDEX ix_projects_location ON projects USING GIST (location);
CREATE INDEX ix_projects_status ON projects (status);

-- ---------------------------------------------------------------------------
-- project_members: entities attached to a project, with a role (hybrid:
-- controlled tag OR free text, same pattern as entity skills).
-- ---------------------------------------------------------------------------
CREATE TABLE project_members (
    project_id     UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    entity_id      UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    role_tag_id    UUID REFERENCES tags(id),
    role_free_text TEXT,
    status         TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('invited', 'confirmed', 'removed')),
    joined_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, entity_id),
    CHECK (role_tag_id IS NOT NULL OR role_free_text IS NOT NULL)
);

CREATE INDEX ix_project_members_entity ON project_members (entity_id);
