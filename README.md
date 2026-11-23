# KBFA Production Connect

A searchable database + web UI for the film/video/event production
industry: individuals and businesses list skills, equipment, locations,
and contacts; they connect to each other and to projects (LinkedIn-style),
and production leads search/discover entities across those facets.

## Status

Phase 0 schema design is done and validated (see `db/`). Phase 1 — a
FastAPI backend (`backend/`) implementing the entities/tags/connections/
projects API against that schema — is scaffolded and working locally.
No frontend yet.

## Backend (`backend/`)

Python 3.12 + FastAPI + SQLAlchemy (async, `asyncpg`) + GeoAlchemy2.
Endpoints mirror the facets validated in `db/schema/002_prototype_queries.sql`:
full-text + fuzzy entity search, controlled-tag AND-faceting, PostGIS
proximity, 1st/2nd-degree connection traversal, and project rosters.

```bash
cd backend
python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env   # edit DATABASE_URL for your local Postgres user
.venv/bin/uvicorn app.main:app --reload
```

Interactive API docs at `http://127.0.0.1:8000/docs` once running. No
auth yet — matches the open "auth approach" item in the hosting section
below. `Dockerfile` builds a container suitable for the proposed App
Runner/Fargate deployment.

## Decisions carried in from planning

- **Primary store: Aurora PostgreSQL** (not DynamoDB, not MySQL). JSONB +
  GIN for flexible attributes, native full-text search (`tsvector`) +
  `pg_trgm` for fuzzy matching, PostGIS for location/proximity. DynamoDB
  was rejected as primary because the core feature — ad hoc multi-facet
  search across flexible attributes, multi-hop connections — doesn't fit
  its access-pattern-first modeling without immediately bolting on
  OpenSearch. Revisit DynamoDB only for a narrow high-throughput
  sub-problem later (e.g. an activity feed); consider Neptune (graph) or
  OpenSearch (search-at-scale) only as later additions fed from Postgres
  via CDC, not day-one requirements.
- **Skill/equipment taxonomy: hybrid.** A curated controlled vocabulary
  (`tags` table, with `aliases` for synonyms like "DP" → "Director of
  Photography") for the common/searchable cases, PLUS a free-text overflow
  field directly on `entities` (`free_text_skills`) for anything that
  doesn't fit yet. Both feed the same full-text search index. New
  free-text entries get periodically reviewed and promoted into `tags` —
  avoids blocking launch on an exhaustive upfront taxonomy while still
  getting good facet/filter quality for the common cases.

## Schema

See [`db/schema/001_core_schema.sql`](db/schema/001_core_schema.sql) for
the full DDL. Summary:

| Table | Purpose |
|---|---|
| `entity_types` | Lookup: individual vs. business, plus sub-category (crew, talent, production company, rental house, studio, vendor...). |
| `tags` | Controlled vocabulary for skills/equipment/roles, with `category` and `aliases` for synonym matching. |
| `entities` | The individuals/businesses themselves — name, bio, contact JSONB, `location` (PostGIS geography point), `free_text_skills` (hybrid overflow), `metadata` JSONB for anything else flexible, and a generated `search_vector`. |
| `entity_tags` | Many-to-many entity ↔ controlled tag. |
| `connections` | LinkedIn-style mutual edge between two entities (`requester`/`recipient` + `status`), with a generated canonical-pair column so a pair can't have duplicate rows regardless of who initiated. |
| `projects` | A job/production, with its own `location`, dates, and generated `search_vector`. |
| `project_members` | Entities attached to a project, with a role that's either a controlled tag or free text (same hybrid pattern as skills). |

Known simplifications, worth revisiting later:
- `project_members` is one row per (project, entity) — an entity can't
  currently hold two distinct roles on the same project without a schema
  change (e.g. a join table keyed `(project_id, entity_id, role_tag_id)`).
- `entity_types` and `tags.category`/`project_type` are plain text/lookup
  rows, not a deeper hierarchy — fine for a launch-scale taxonomy, may
  need a proper tree if categories get deep.

## Search prototyping — validated

[`db/schema/002_prototype_queries.sql`](db/schema/002_prototype_queries.sql)
has 13 queries, all run successfully against
[`db/seed/001_sample_data.sql`](db/seed/001_sample_data.sql) (11 sample
entities, 20 controlled tags, connections, 2 projects) on a local
Postgres 18 + PostGIS 3.7 instance. Confirmed working:

1. **Full-text search** (`tsvector`/`to_tsquery`, GIN-indexed) across
   name/headline/bio/free-text skills — e.g. "drone" correctly surfaces
   the drone pilot via her free-text skills, not just her headline.
2. **Controlled-tag faceting** — AND-ing two `entity_tags` joins (e.g.
   "has DP skill AND owns a RED Komodo") correctly narrows to the one
   matching entity instead of everyone who has either.
3. **Alias/fuzzy matching** (`pg_trgm` `similarity`/`%` operator, plus the
   `tags.aliases` array) — "DP" resolves to "Director of Photography" via
   alias lookup; a misspelled tag ("directr of photografy") and a
   misspelled name ("Jorje Alvares") both resolve correctly via trigram
   similarity. This is the key validation for the hybrid-taxonomy bet:
   fuzzy/alias matching covers the gap between free text and controlled
   tags well enough not to need the vocabulary to be exhaustive upfront.
4. **Proximity search** (PostGIS `ST_DWithin`/`ST_Distance` on
   `geography(Point,4326)`) — "within 15 miles of Manhattan" correctly
   returns only the NYC-area entities, sorted nearest-first, and excludes
   the Atlanta/LA ones.
5. **Combined multi-facet search** — skill tag + proximity together (e.g.
   "Gaffer within 20 miles of NYC"), and the equivalent single-search-box
   version using full text instead of a picked tag — both return the
   same correct result, confirming the UI can offer either a faceted
   filter panel or a plain search box over the same data.
6. **Network traversal** — 1st-degree connections (direction-agnostic,
   via the `requester`/`recipient` CASE pattern) and a 2nd-degree
   "people you may know" query (excluding self and existing 1st-degree)
   both return correct results.
7. **Project roster resolution** — `project_members` correctly resolves a
   member's role whether it came from a controlled tag or free text, via
   `coalesce(tag.label, role_free_text)`.

### Running the prototype yourself

```bash
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export LC_ALL="en_US.UTF-8"
pg_ctl -D /opt/homebrew/var/postgresql@18 -l .devdb/pg18.log start   # if not already running
psql -d kbfa_dev -f db/schema/001_core_schema.sql   # on a fresh db
psql -d kbfa_dev -f db/seed/001_sample_data.sql
psql -d kbfa_dev -f db/schema/002_prototype_queries.sql
```

(`postgresql@18`, not `@16` — this machine's Homebrew `postgis` bottle is
only built against PG18/19. Aurora PostgreSQL's own supported major
version should be picked independently when provisioning — see hosting
section below — this is purely a local prototyping detail.)

## Proposed AWS hosting shape

| Layer | Proposed service | Why |
|---|---|---|
| Database | **Aurora PostgreSQL Serverless v2** | Matches the settled decision above; Serverless v2 auto-scales capacity for a new product with unpredictable early load, avoiding a fixed-instance commitment before real traffic patterns are known. Confirm the target engine version supports PostGIS (Aurora PostgreSQL has supported the PostGIS extension for years, but pin the exact version when provisioning). |
| Backend API | **AWS App Runner** (first choice) or **Fargate** (if more control over networking/sidecars is needed) | App Runner is the lowest-ops option for a containerized API with a database behind it — no cluster/VPC-networking setup to hand-roll, built-in autoscaling and HTTPS. Fargate is the fallback if the app later needs things App Runner doesn't expose (custom VPC routing, multiple containers per task, etc.). Lambda + API Gateway is a plausible alternative but less natural here since most requests are straightforward CRUD/search against Postgres, not bursty/event-driven work — avoids Lambda's connection-pooling-to-Postgres friction (would need RDS Proxy) for little benefit at this stage. |
| Frontend | **AWS Amplify Hosting** | Simplest path for a standard web app (static build + CI from a git push), handles CDN/HTTPS/custom domain without assembling S3+CloudFront by hand. Revisit S3+CloudFront directly only if Amplify's build/hosting model becomes a constraint later. |
| Networking | Backend (App Runner/Fargate) and Aurora in the same VPC, Aurora in private subnets only | Standard pattern — database never gets a public endpoint; only the backend reaches it. |
| Search beyond Postgres (later, not day-one) | OpenSearch, fed via CDC (e.g. AWS DMS or a logical-replication-based pipeline) from Aurora | Only if full-text/faceted search outgrows what `tsvector`+GIN+`pg_trgm` can do at scale — not needed to launch, per the settled decision. |
| Graph beyond Postgres (later, not day-one) | Neptune, fed via CDC from Aurora | Only if multi-hop network queries (3rd-degree+, recommendation-style graph traversal) outgrow recursive CTEs on `connections` — the 2nd-degree query above already works fine as a plain CTE at this scale. |

Open items to confirm with the user before provisioning anything real:
1. Target AWS region(s) — affects Aurora Serverless v2 availability and
   latency for the likely user base.
2. Expected initial scale (rough entity count, concurrent production
   leads searching) — mostly to sanity-check that Serverless v2's
   minimum ACU setting won't be wasteful or, conversely, that a single
   Aurora writer is enough to start (no read replica needed yet).
3. Auth approach for entities signing up/managing their own profile
   (Cognito is the natural default on AWS, but not yet decided).
4. Whether the backend framework/language is already decided, or still
   open — affects the App Runner vs. Fargate choice's exact packaging.

## Next steps

1. Pick the backend framework/language and confirm the AWS hosting
   specifics above with the user.
2. Stand up Aurora PostgreSQL Serverless v2 (dev cluster) from this same
   schema, confirm PostGIS/`pg_trgm` are available on it the same as the
   local prototype.
3. Decide on an auth approach for entities managing their own profiles.
4. Start the backend API (entities CRUD, tag/skill management, search
   endpoint, connections, projects) against this schema.
5. Start the frontend (entity profile pages, search UI, connection
   requests, project rosters).
6. Build the tag-promotion workflow (reviewing `free_text_skills` entries
   across entities and promoting common ones into `tags`) — not needed
   for launch, but needed soon after to keep the hybrid taxonomy healthy.
