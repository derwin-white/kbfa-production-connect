-- Prototype faceted-search queries, validated against db/seed/001_sample_data.sql.
-- Grouped by the mechanism each one exercises.

-- =====================================================================
-- 1. Full-text search (tsvector + GIN) — free-text query across
--    name/headline/bio/free-text skills
-- =====================================================================
-- "Who matches 'drone'?"
SELECT name, headline, ts_rank(search_vector, query) AS rank
FROM entities, to_tsquery('english', 'drone') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Phrase-ish multi-term: "sound mixer" via OR of stems
SELECT name, headline, ts_rank(search_vector, query) AS rank
FROM entities, to_tsquery('english', 'sound & mixer') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- =====================================================================
-- 2. Controlled-tag faceted filtering (hybrid taxonomy, structured side)
-- =====================================================================
-- "Entities with BOTH the DP skill tag AND the RED Komodo equipment tag"
SELECT e.name, e.headline
FROM entities e
WHERE e.id IN (
    SELECT entity_id FROM entity_tags et JOIN tags t ON t.id = et.tag_id
    WHERE t.label = 'Director of Photography'
)
AND e.id IN (
    SELECT entity_id FROM entity_tags et JOIN tags t ON t.id = et.tag_id
    WHERE t.label = 'RED Komodo 6K'
);

-- "All distinct skills/equipment held by a given entity" (tag facets for a profile page)
SELECT t.tag_type, t.label, t.category
FROM entity_tags et
JOIN tags t ON t.id = et.tag_id
JOIN entities e ON e.id = et.entity_id
WHERE e.name = 'Maya Chen'
ORDER BY t.tag_type, t.category;

-- =====================================================================
-- 3. Fuzzy / alias matching (pg_trgm + aliases array) — the "hybrid"
--    taxonomy's answer to "DP" meaning "Director of Photography", and
--    to typos in free-text search
-- =====================================================================
-- Alias lookup: searching "DP" should resolve to the controlled tag
SELECT id, label, category
FROM tags
WHERE 'DP' = ANY(aliases) OR label ILIKE 'DP';

-- Typo-tolerant tag label search ("directr of photografy")
SELECT label, similarity(label, 'directr of photografy') AS sim
FROM tags
WHERE label % 'directr of photografy'
ORDER BY sim DESC;

-- Typo-tolerant entity name search ("Jorje Alvares")
SELECT name, similarity(name, 'Jorje Alvares') AS sim
FROM entities
WHERE name % 'Jorje Alvares'
ORDER BY sim DESC;

-- =====================================================================
-- 4. Proximity search (PostGIS geography)
-- =====================================================================
-- "Entities within 15 miles of Manhattan (-73.9857, 40.7484), nearest first"
SELECT name, headline, location_label,
       round((ST_Distance(location, ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography) / 1609.34)::numeric, 1) AS miles
FROM entities
WHERE location IS NOT NULL
  AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography, 15 * 1609.34)
ORDER BY miles ASC;

-- =====================================================================
-- 5. Combined multi-facet query — the realistic "production lead" search:
--    skill tag + free-text fallback + proximity + active only, ranked
-- =====================================================================
-- "Find a Gaffer within 20 miles of NYC"
SELECT e.name, e.headline, e.location_label,
       round((ST_Distance(e.location, ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography) / 1609.34)::numeric, 1) AS miles
FROM entities e
WHERE e.is_active
  AND e.id IN (SELECT entity_id FROM entity_tags et JOIN tags t ON t.id = et.tag_id WHERE t.label = 'Gaffer')
  AND e.location IS NOT NULL
  AND ST_DWithin(e.location, ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography, 20 * 1609.34)
ORDER BY miles ASC;

-- Same search but the production lead typed free text instead of picking a
-- tag filter ("gaffer near nyc") — full text + proximity, no controlled tag
-- required at all. This is the query shape for a single search box.
SELECT e.name, e.headline, e.location_label, ts_rank(e.search_vector, query) AS rank
FROM entities e, to_tsquery('english', 'gaffer') query
WHERE e.search_vector @@ query
  AND e.location IS NOT NULL
  AND ST_DWithin(e.location, ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography, 20 * 1609.34)
ORDER BY rank DESC;

-- =====================================================================
-- 6. Network traversal (connections edge table)
-- =====================================================================
-- "Maya Chen's direct, accepted connections"
SELECT other.name, other.headline
FROM connections c
JOIN entities self ON self.name = 'Maya Chen'
JOIN entities other ON other.id = (
    CASE WHEN c.requester_entity_id = self.id THEN c.recipient_entity_id ELSE c.requester_entity_id END
)
WHERE (c.requester_entity_id = self.id OR c.recipient_entity_id = self.id)
  AND c.status = 'accepted';

-- "2nd-degree network" — people connected to Maya Chen's direct connections,
-- excluding Maya herself and her direct connections (LinkedIn "People you
-- may know" shape)
WITH self AS (SELECT id FROM entities WHERE name = 'Maya Chen'),
first_degree AS (
    SELECT CASE WHEN c.requester_entity_id = self.id THEN c.recipient_entity_id ELSE c.requester_entity_id END AS entity_id
    FROM connections c, self
    WHERE (c.requester_entity_id = self.id OR c.recipient_entity_id = self.id) AND c.status = 'accepted'
)
SELECT DISTINCT e.name, e.headline
FROM connections c
JOIN first_degree fd ON (c.requester_entity_id = fd.entity_id OR c.recipient_entity_id = fd.entity_id)
JOIN entities e ON e.id = (CASE WHEN c.requester_entity_id = fd.entity_id THEN c.recipient_entity_id ELSE c.requester_entity_id END)
WHERE c.status = 'accepted'
  AND e.id NOT IN (SELECT id FROM self)
  AND e.id NOT IN (SELECT entity_id FROM first_degree);

-- =====================================================================
-- 7. Project roster lookup (projects + project_members, both tag and
--    free-text roles resolved to a display label)
-- =====================================================================
SELECT p.name AS project, e.name AS entity,
       coalesce(t.label, pm.role_free_text) AS role
FROM project_members pm
JOIN projects p ON p.id = pm.project_id
JOIN entities e ON e.id = pm.entity_id
LEFT JOIN tags t ON t.id = pm.role_tag_id
ORDER BY p.name, role;
