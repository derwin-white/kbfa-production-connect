-- KBFA Production Connect — taxonomy expansion, wave 2
-- Follow-up to db/schema/003_expand_taxonomy.sql, at the user's direct
-- request to keep growing the controlled vocabulary with real
-- manufacturer/role data rather than guessed entries. Sourced from:
--   * Canon's Cinema EOS lineup (official Canon newsroom / anniversary
--     coverage, Nov 2026) — C50, C70, C80, C400, C500 Mark II, R5 C.
--   * Sony's Cinema Line tiers (Sony's own product pages + trade press) —
--     VENICE, Burano, FX3, FX30.
--   * Trade-press lighting roundups (Pro Moviemaker, Adorama) for the
--     specific flagship models of brands already represented at the
--     department level (Nanlux, Litepanels, Godox, Quasar Science).
--   * Toronto Film Office's crew-role guide and documentary/development
--     job-posting patterns, for office/development/documentary roles this
--     project's taxonomy didn't have granular coverage for yet.
-- See the README's "Taxonomy expansion" section for the full picture
-- (wave 1 + this wave) and how to extend it again.
--
-- Idempotent, same pattern as 003: every INSERT targets the existing
-- unique constraints with ON CONFLICT DO NOTHING, safe to re-run.
--
-- Does NOT duplicate anything already in 001's seed or 003's wave 1 —
-- e.g. Executive Producer (role) and Location Manager (skill) were
-- already added in wave 1 and are NOT repeated here, even though they
-- were called out again in this round's request.

-- ---------------------------------------------------------------------------
-- tags: skill-type additions — office/development, documentary,
-- post-production, VFX, and live-event roles wave 1 didn't cover yet.
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    -- Production Management / Office
    ('skill', 'Development Executive', 'Production Management', ARRAY['Dev Exec']),
    ('skill', 'Production Executive',  'Production Management', ARRAY[]::text[]),
    ('skill', 'Script Coordinator',    'Production Management', ARRAY['Story Coordinator']),
    ('skill', 'Story Editor',          'Production Management', ARRAY[]::text[]),
    ('skill', 'Writers'' Assistant',    'Production Management', ARRAY[]::text[]),
    ('skill', 'Production Runner',     'Production Management', ARRAY['Runner']),

    -- Documentary (a sub-discipline with its own common titles, not covered
    -- by wave 1's narrative-leaning department list)
    ('skill', 'Field Producer',         'Documentary', ARRAY[]::text[]),
    ('skill', 'Documentary Researcher', 'Documentary', ARRAY['Researcher']),
    ('skill', 'Archival Producer',      'Documentary', ARRAY['Archival Researcher']),

    -- Post-Production
    ('skill', 'Colorist Assistant',   'Post-Production', ARRAY[]::text[]),
    ('skill', 'Mastering Engineer',   'Post-Production', ARRAY['DCP Mastering Engineer']),
    ('skill', 'Subtitling Editor',    'Post-Production', ARRAY['Closed Captioning Editor']),
    ('skill', 'Media Manager',        'Post-Production', ARRAY['Digital Archivist']),

    -- VFX & Animation
    ('skill', 'Pipeline Technical Director', 'VFX & Animation', ARRAY['Pipeline TD']),
    ('skill', 'Render Wrangler',              'VFX & Animation', ARRAY[]::text[]),

    -- Live Events & Broadcast
    ('skill', 'Floor Manager',          'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Festival Director',      'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Volunteer Coordinator',  'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Teleprompter Operator',  'Live Events & Broadcast', ARRAY[]::text[])
ON CONFLICT (tag_type, lower(label)) DO NOTHING;

-- ---------------------------------------------------------------------------
-- tags: equipment-type additions — real Canon/Sony cinema camera models,
-- named lighting flagships, lens sets, and live-event AV gear not yet in
-- the vocabulary. Wave 1 already added ARRI Alexa 35/65, RED V-Raptor,
-- Sony Venice 2/FX6, Canon C300 Mark III, Blackmagic URSA Mini Pro 12K,
-- Aputure 1200D — none of those are repeated here.
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    -- Canon Cinema EOS
    ('equipment', 'Canon EOS C70',          'Camera', ARRAY['C70']),
    ('equipment', 'Canon EOS C500 Mark II', 'Camera', ARRAY['C500 Mark II']),
    ('equipment', 'Canon EOS C400',         'Camera', ARRAY['C400']),
    ('equipment', 'Canon EOS C80',          'Camera', ARRAY['C80']),
    ('equipment', 'Canon EOS C50',          'Camera', ARRAY['C50']),
    ('equipment', 'Canon EOS R5 C',         'Camera', ARRAY['R5C']),

    -- Sony Cinema Line
    ('equipment', 'Sony Burano', 'Camera', ARRAY[]::text[]),
    ('equipment', 'Sony FX3',    'Camera', ARRAY[]::text[]),
    ('equipment', 'Sony FX30',   'Camera', ARRAY[]::text[]),
    ('equipment', 'Sony VENICE', 'Camera', ARRAY['Venice (Original)']),

    -- Lighting flagships
    ('equipment', 'Nanlux Evoke 5000B',          'Lighting', ARRAY['Evoke 5000B']),
    ('equipment', 'Litepanels Gemini 2x1 Hard',  'Lighting', ARRAY['Gemini 2x1']),
    ('equipment', 'Godox KNOWLED MG1200Bi',      'Lighting', ARRAY['MG1200Bi']),
    ('equipment', 'Quasar Science Rainbow 2',    'Lighting', ARRAY['Rainbow 2']),

    -- Lenses
    ('equipment', 'Leica Summicron-C Set', 'Lenses', ARRAY['Summicron-C']),
    ('equipment', 'Sigma Cine Prime Set',  'Lenses', ARRAY['Sigma Cine Primes']),

    -- Live-event / broadcast AV
    ('equipment', 'Teleprompter System',                'Event AV Equipment', ARRAY['Teleprompter']),
    ('equipment', 'Wireless Video Transmission System', 'Event AV Equipment', ARRAY['Teradek']),
    ('equipment', 'Video Switcher / Vision Mixer Hardware', 'Event AV Equipment', ARRAY['Vision Mixer Hardware']),
    ('equipment', 'Intercom / Comms System',            'Event AV Equipment', ARRAY['Clear-Com'])
ON CONFLICT (tag_type, lower(label)) DO NOTHING;
