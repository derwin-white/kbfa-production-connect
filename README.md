# KBFA Production Connect

A searchable database + web UI for the film/video/event production
industry: individuals and businesses list skills, equipment, locations,
and contacts; they connect to each other and to projects (LinkedIn-style),
and production leads search/discover entities across those facets.

## Status

Phase 0 schema design is done and validated (see `db/`). Phase 1 — a
FastAPI backend (`backend/`) and a React frontend (`frontend/`)
implementing the entities/tags/connections/projects experience against
that schema — are scaffolded and working locally, verified end-to-end
in a browser against the live API.

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

**Fixed bug (2026-11-24):** `POST /entities/` and `POST /projects/` were
broken since the backend was first scaffolded — the `Entity`/`Project`
SQLAlchemy models mapped `search_vector` as a plain column, so the ORM
tried to INSERT an explicit `NULL` into it; Postgres rejects that for a
`GENERATED ALWAYS ... STORED` column with `cannot insert a non-DEFAULT
value into column "search_vector"`. Fixed by adding
`server_default=FetchedValue()` to both models' `search_vector` mapping
(`app/models/entities.py`, `app/models/projects.py`) — this tells
SQLAlchemy not to send the column on INSERT/UPDATE and to read the
server-computed value back instead. Caught while building the admin
screen below, which was the first thing to actually exercise entity/
project creation end-to-end through a UI.

## Frontend (`frontend/`)

React 19 + TypeScript + Vite, routed with `react-router-dom`, data
fetching via `@tanstack/react-query` against the backend above. Screens:

- **Search** — free-text + fuzzy search, controlled-tag facet picker,
  "near me" proximity filter via the browser's Geolocation API, and a
  **Cards / List view toggle** (remembered in `localStorage`) — Cards is
  the original card-grid layout, List is a dense table (Name, Type,
  Headline/Location, Tags, Distance when location filtering is active)
  for scanning more results at once.
- **Entity detail** — profile, tags, connections, 2nd-degree "people you
  may know."
- **Projects** — list + detail page showing the roster.
- **Admin** — forms to add a person/business (with controlled-tag
  attachment via the same type-ahead picker used in Search), add a new
  skill/equipment/role tag, and add a project. Everything saves directly
  to the live database via the existing backend CRUD endpoints — no
  draft/review step.

```bash
cd frontend
npm install
cp .env.example .env   # VITE_API_BASE_URL, defaults to http://127.0.0.1:8000
npm run dev
```

Needs the backend running (see above) to show real data. No auth/signup
flow yet — matches the backend's current state. The Admin screen has no
access control either — anyone who can load the app can write to the
database; revisit once auth exists.

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
| `entity_types` | Lookup: individual vs. business, plus sub-category (crew, talent, production company, rental house, studio, vendor, post-production house, talent/casting agency, event production company, ad agency...). |
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

## Taxonomy expansion

[`db/schema/003_expand_taxonomy.sql`](db/schema/003_expand_taxonomy.sql) grows
the controlled vocabulary from the original schema-prototyping session's 20
tags to **188** (123 skill + 53 equipment + 12 role), plus 4 new
`entity_types` business sub-categories (post-production house, talent/casting
agency, event production company, ad agency). This was researched, not
guessed — against [IMDb's professional credit categories](https://help.imdb.com/article/contribution/filmography-credits/new-credit-categories/GVX4ZP2JX4W5QWAN)
(45 as of its Nov 2025 update) and [StudioBinder's film crew position
guide](https://www.studiobinder.com/blog/film-crew-positions/), then extended
with live-event/broadcast roles and equipment so the taxonomy actually covers
this project's stated scope (film/video **and events**), not just film sets.

Granular departments added (skill tags): Camera, Grip & Electric, Sound,
Art, Costume & Wardrobe, Hair & Makeup, Production Management, Locations,
Transportation, Catering & Craft Service, Post-Production, VFX & Animation,
Stunts & Special Effects, Casting, Music, Choreography & Intimacy,
Puppetry, Publicity & Marketing, Legal & Finance, Medical & Safety, and
Live Events & Broadcast. Equipment added: camera bodies, lens sets,
lighting instruments, grip gear, camera support, drones, sound gear,
power/distro, live-event AV gear, and post-production tools. A smaller set
of pure producing/directing titles (Executive Producer, Showrunner, 2nd AD,
etc.) was added as `role`-type tags, extending the original three
(Director, Producer, Production Coordinator).

The migration also normalizes 3 pre-existing tags' `category` values
(`Gaffer`/`Key Grip`: `Lighting`/`Grip` → `Grip & Electric`; `Sound Mixer`:
`Sound` → `Sound Department`) so the original seed tags group consistently
with the new ones instead of splitting into near-duplicate categories.

**Applied and verified against the local dev database** (not just written):
every `INSERT`/`UPDATE` targets the existing unique constraints with
`ON CONFLICT ... DO NOTHING`, so the file is idempotent — confirmed by
running it twice and seeing `INSERT 0 0` on the second pass. Did **not**
touch `db/seed/001_sample_data.sql` or assign any new tags to the sample
entities — this is vocabulary, not seed data. The sample full-text search
query (`"drone"` → Priya Natarajan) was re-run afterward and still returns
the same correct result, confirming the expansion didn't disturb existing
search behavior.

Not yet done: no new entities/equipment assignments using the expanded
vocabulary (the sample data is unchanged), and the tag-promotion workflow
(reviewing `free_text_skills` for values that should graduate into this
controlled list) is still unbuilt — unchanged open items from before.

**Wave 2 (2026-11-24):** [`db/schema/004_expand_taxonomy_wave2.sql`](db/schema/004_expand_taxonomy_wave2.sql)
adds another **38 tags** (19 skill + 19 equipment) — real Canon Cinema
EOS and Sony Cinema Line camera models (C50/C70/C80/C400/C500 Mark II/
R5 C, Burano/FX3/FX30/VENICE), named lighting flagships (Nanlux, Litepanels,
Godox, Quasar Science), two lens sets, live-event AV gear (teleprompter,
wireless video, vision-mixer hardware, intercom), and office/development/
documentary/VFX/live-event roles (Development Executive, Script
Coordinator, Field Producer, Documentary Researcher, Pipeline TD, Floor
Manager, Festival Director, etc.) that wave 1 didn't reach. Sourced from
Canon's and Sony's own product pages/newsroom and trade-press lighting
roundups, not guessed. Total vocabulary is now **227 tags** (142 skill +
73 equipment + 12 role). Same idempotent `ON CONFLICT DO NOTHING` pattern,
verified the same way (applied, re-run to confirm no-op, existing search
query re-checked). Note: `Executive Producer` (role) and `Location
Manager` (skill) were requested again in this round but were already
added in wave 1 — not duplicated.

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
psql -d kbfa_dev -f db/schema/003_expand_taxonomy.sql   # expanded tag vocabulary, safe to re-run
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

Tracked on the project's own [GitHub Projects backlog](https://github.com/users/derwin-white/projects/1/views/1).
As of 2026-11-24:

- **Done this round:** granular taxonomy expansion (227 tags — see
  "Taxonomy expansion" above); the Admin screen for entering data
  (entities, tags, projects — backlog #4); Cards/List view toggle for
  search results (backlog #1).
- **Still open on the backlog:** allow users to submit custom skill/
  equipment tags beyond the controlled vocabulary (#3, a self-service
  version of what the Admin tag form currently does as an unrestricted
  "anyone can add a tag" form).
- **Still open, not yet on the backlog as separate items:** stand up
  Aurora PostgreSQL Serverless v2 and confirm PostGIS/`pg_trgm` there;
  decide an auth approach (the Admin screen currently has none); build
  the tag-promotion workflow (reviewing `free_text_skills` for values
  that should graduate into the controlled vocabulary); AWS hosting
  specifics (region, scale) still need confirming with the user per the
  table above.
