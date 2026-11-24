-- KBFA Production Connect — demo expansion
-- Adds 20 more individual entities (across departments the original
-- 001_sample_data.sql seed didn't touch: VFX, stunts, art, costume,
-- hair/makeup, music, casting, locations, production office, sound) plus
-- 2 supporting businesses, and 10 projects. Projects are inspired by real
-- recent (2025/2026) theatrical releases, each renamed to a distinct
-- fictional title per the user's instruction — not the real titles, and
-- descriptions are original genre-flavor text, not copied synopses:
--   Spider-Man: Brand New Day   -> Web Slinger: Brand New Dawn
--   Michael (MJ biopic)         -> Moonwalker: A Life in Rhythm
--   The Super Mario Galaxy Movie-> Starlight Plumbers: Galactic Leap
--   Toy Story 5                 -> Playroom Pals 5
--   The Odyssey                 -> The Long Voyage Home
--   Project Hail Mary           -> Last Light Protocol
--   Scream 7                    -> Shriek VII
--   Minions & Monsters          -> Tiny Troublemakers & Monsters
--   Wuthering Heights           -> Stormcliff Manor
--   Avatar: Fire and Ash        -> World Beyond: Embers Rising
--
-- Each project has a realistic-looking roster (mix of the new entities
-- here and the original 001 seed's entities — freelancers crossing
-- between productions, same as real crews do), using role_tag_id where a
-- controlled tag fits and role_free_text for the two business vendors.
-- Idempotent-ish in spirit (safe to re-run against a fresh DB loaded from
-- 001+002 schema and 001 seed first) but not ON CONFLICT-guarded like the
-- 003/004 taxonomy migrations — this is seed data, re-running it twice
-- against the same DB would duplicate rows, same caveat as 001.

-- ---------------------------------------------------------------------------
-- Entities (new individuals)
-- ---------------------------------------------------------------------------
INSERT INTO entities (entity_type_id, name, headline, bio, contact, free_text_skills, location_label, location, metadata)
VALUES
    ((SELECT id FROM entity_types WHERE code='crew'),
     'Theo Bramwell', 'Visual Effects Supervisor — Los Angeles, CA',
     'VFX supervisor with a background in large-scale tentpole and animated features, previs through final comp.',
     '{"email":"theo.bramwell@example.com","imdb":"nm2201001"}', ARRAY['pipeline TD liaison'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2468, 34.0407), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Ava Lindqvist', 'Compositor — Los Angeles, CA',
     'Senior compositor, Nuke-based pipelines, creature and environment work for feature animation and VFX-heavy live action.',
     '{"email":"ava.lindqvist@example.com"}', ARRAY['Nuke', 'rotoscope supervision'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.4452, 34.0194), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Marcus Webb', 'Stunt Coordinator — Atlanta, GA',
     'Stunt coordinator specializing in vehicle work and wire gags for action tentpoles and horror sequels alike.',
     '{"email":"marcus.webb@example.com"}', ARRAY['fight choreography'],
     'Atlanta, GA', ST_SetSRID(ST_MakePoint(-84.4277, 33.7756), 4326)::geography, '{"union": "SAG-AFTRA Stunt"}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Jasmine Cole', 'Stunt Performer — Atlanta, GA',
     'Stunt performer and double, precision driving and high-fall certified.',
     '{"email":"jasmine.cole@example.com"}', ARRAY['precision driving'],
     'Atlanta, GA', ST_SetSRID(ST_MakePoint(-84.3963, 33.7701), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Noah Kessler', 'Production Designer — Los Angeles, CA',
     'Production designer across period pieces and large-scale sci-fi builds.',
     '{"email":"noah.kessler@example.com"}', ARRAY['concept art direction'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2851, 34.0975), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Ruth Alvarado', 'Set Decorator — Los Angeles, CA',
     'Set decorator, strong period-accurate sourcing and practical dressing.',
     '{"email":"ruth.alvarado@example.com"}', ARRAY[]::text[],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2004, 34.0522), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Elena Marchetti', 'Costume Designer — Manhattan, NY',
     'Costume designer spanning period drama and contemporary music biopics.',
     '{"email":"elena.marchetti@example.com"}', ARRAY['period tailoring'],
     'Manhattan, NY', ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Dominique Price', 'Key Hair Stylist — Brooklyn, NY',
     'Key hair for narrative features and music biopics, wig work a specialty.',
     '{"email":"dominique.price@example.com"}', ARRAY['wig styling'],
     'Brooklyn, NY', ST_SetSRID(ST_MakePoint(-73.9496, 40.6501), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Farrah Simmons', 'Key Makeup Artist — Bronx, NY',
     'Key makeup artist, beauty and character work across film and music biopics.',
     '{"email":"farrah.simmons@example.com"}', ARRAY[]::text[],
     'Bronx, NY', ST_SetSRID(ST_MakePoint(-73.9262, 40.8296), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Victor Hale', 'SFX Makeup Artist — Decatur, GA',
     'Prosthetics and SFX makeup artist, horror and genre work.',
     '{"email":"victor.hale@example.com"}', ARRAY['prosthetic sculpting'],
     'Decatur, GA', ST_SetSRID(ST_MakePoint(-84.3505, 33.7627), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Julian Osei', 'Composer — Los Angeles, CA',
     'Film composer, orchestral and hybrid electronic scores for animated and live-action features.',
     '{"email":"julian.osei@example.com"}', ARRAY['orchestration'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.3617, 34.0900), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Renee Castillo', 'Music Supervisor — Los Angeles, CA',
     'Music supervisor, needle-drop licensing and original song placement for biopics and animated features.',
     '{"email":"renee.castillo@example.com"}', ARRAY['sync licensing'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.4065, 34.0194), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Harold Finnegan', 'Casting Director — Manhattan, NY',
     'Casting director, principal and voice casting for feature film and animation.',
     '{"email":"harold.finnegan@example.com"}', ARRAY['voice casting'],
     'Manhattan, NY', ST_SetSRID(ST_MakePoint(-73.9772, 40.7527), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Celia Dunmore', 'Location Manager — Marietta, GA',
     'Location manager, Southeast-region permitting and scouting specialist.',
     '{"email":"celia.dunmore@example.com"}', ARRAY['permit negotiation'],
     'Marietta, GA', ST_SetSRID(ST_MakePoint(-84.5144, 33.8034), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Grace Liu', 'Unit Production Manager — Los Angeles, CA',
     'UPM across animated and live-action tentpoles, strong studio-side budgeting background.',
     '{"email":"grace.liu@example.com"}', ARRAY[]::text[],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2673, 34.1016), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Owen Baptiste', 'Script Supervisor — Manhattan, NY',
     'Script supervisor, continuity across narrative features and period pieces.',
     '{"email":"owen.baptiste@example.com"}', ARRAY[]::text[],
     'Manhattan, NY', ST_SetSRID(ST_MakePoint(-73.9834, 40.7282), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Miles Tran', 'Boom Operator — Hoboken, NJ',
     'Boom operator, narrative features and music biopics across the tri-state area.',
     '{"email":"miles.tran@example.com"}', ARRAY[]::text[],
     'Hoboken, NJ', ST_SetSRID(ST_MakePoint(-74.0324, 40.7439), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Anjali Deshmukh', 'Sound Designer — Venice, CA',
     'Sound designer, sci-fi and genre feature work, strong foley-direction background.',
     '{"email":"anjali.deshmukh@example.com"}', ARRAY['foley direction'],
     'Venice, CA', ST_SetSRID(ST_MakePoint(-118.4912, 34.0195), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Liam Forsythe', 'Gaffer — Vancouver, BC',
     'Gaffer based in Vancouver, large-scale studio productions and epic-scale location shoots.',
     '{"email":"liam.forsythe@example.com"}', ARRAY[]::text[],
     'Vancouver, BC', ST_SetSRID(ST_MakePoint(-123.1207, 49.2827), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Sofia Delgado', 'Camera Operator — Vancouver, BC',
     'Camera operator, Steadicam-certified, epic-scale location and studio work.',
     '{"email":"sofia.delgado@example.com"}', ARRAY['Steadicam'],
     'Vancouver, BC', ST_SetSRID(ST_MakePoint(-123.1156, 49.2608), 4326)::geography, '{}');

-- ---------------------------------------------------------------------------
-- Entities (2 supporting businesses — populating entity_types added in
-- 003_expand_taxonomy.sql that had no entities yet: post_house, event_production_co)
-- ---------------------------------------------------------------------------
INSERT INTO entities (entity_type_id, name, headline, bio, contact, free_text_skills, location_label, location, metadata)
VALUES
    ((SELECT id FROM entity_types WHERE code='post_house'),
     'Northstar Post & VFX', 'Post-Production & VFX House — Los Angeles, CA',
     'Full-service post house: editorial, color, and VFX for feature film and streaming.',
     '{"email":"bookings@northstarpost.example.com"}', ARRAY[]::text[],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.3004, 34.0928), 4326)::geography, '{}'),

    ((SELECT id FROM entity_types WHERE code='event_production_co'),
     'Bright Spark Premiere Events', 'Premiere & Press Event Production — Los Angeles, CA',
     'Produces studio premieres, press junkets, and talent activations.',
     '{"email":"hello@brightsparkevents.example.com"}', ARRAY[]::text[],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326)::geography, '{}');

-- ---------------------------------------------------------------------------
-- entity_tags: controlled skill/equipment assignments for the 20 new entities
-- ---------------------------------------------------------------------------
INSERT INTO entity_tags (entity_id, tag_id)
SELECT e.id, t.id FROM entities e, tags t
WHERE (e.name, t.label) IN (
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Ava Lindqvist', 'Compositor'),
    ('Marcus Webb', 'Stunt Coordinator'),
    ('Jasmine Cole', 'Stunt Performer'),
    ('Noah Kessler', 'Production Designer'),
    ('Ruth Alvarado', 'Set Decorator'),
    ('Elena Marchetti', 'Costume Designer'),
    ('Dominique Price', 'Key Hair Stylist'),
    ('Farrah Simmons', 'Key Makeup Artist'),
    ('Victor Hale', 'SFX Makeup Artist'),
    ('Julian Osei', 'Composer'),
    ('Renee Castillo', 'Music Supervisor'),
    ('Harold Finnegan', 'Casting Director'),
    ('Celia Dunmore', 'Location Manager'),
    ('Grace Liu', 'Unit Production Manager'),
    ('Owen Baptiste', 'Script Supervisor'),
    ('Miles Tran', 'Boom Operator'),
    ('Miles Tran', 'Sennheiser MKH 416 Shotgun Mic'),
    ('Anjali Deshmukh', 'Sound Designer'),
    ('Liam Forsythe', 'Gaffer'),
    ('Liam Forsythe', 'ARRI SkyPanel S360'),
    ('Sofia Delgado', 'Camera Operator'),
    ('Sofia Delgado', 'Canon EOS C70')
);

-- ---------------------------------------------------------------------------
-- Projects (movie-inspired, renamed)
-- ---------------------------------------------------------------------------
INSERT INTO projects (name, description, project_type, status, location_label, location, start_date, end_date) VALUES
    ('Web Slinger: Brand New Dawn',
     'Studio tentpole following a masked hero navigating a new chapter against a rising criminal syndicate, heavy on practical stunts and large-scale VFX.',
     'Studio Tentpole — Action/Superhero', 'active',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.3287, 34.0928), 4326)::geography, '2026-08-03', NULL),

    ('Moonwalker: A Life in Rhythm',
     'Music biopic tracing a reclusive pop icon''s rise from a tight-knit family act to global superstardom.',
     'Music Biopic', 'completed',
     'Atlanta, GA', ST_SetSRID(ST_MakePoint(-84.3880, 33.7490), 4326)::geography, '2025-03-10', '2025-08-20'),

    ('Starlight Plumbers: Galactic Leap',
     'Animated feature sending two brothers on a cosmic detour through gravity-bending worlds to rescue a kidnapped princess.',
     'Animated Feature', 'active',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2468, 34.0407), 4326)::geography, '2026-02-01', NULL),

    ('Playroom Pals 5',
     'Fifth installment following a beloved toy crew as they help a new kid navigate growing up and letting go.',
     'Animated Sequel', 'planning',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.3617, 34.0900), 4326)::geography, '2027-01-15', NULL),

    ('The Long Voyage Home',
     'Epic-scale adventure retelling a legendary wanderer''s decade-long journey home across mythic seas.',
     'Epic Adventure', 'active',
     'Vancouver, BC', ST_SetSRID(ST_MakePoint(-123.1216, 49.2827), 4326)::geography, '2026-05-01', NULL),

    ('Last Light Protocol',
     'Hard sci-fi thriller: a lone scientist wakes on a deep-space mission with no memory and humanity''s survival on the line.',
     'Sci-Fi Thriller', 'planning',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.4065, 34.0194), 4326)::geography, '2027-03-01', NULL),

    ('Shriek VII',
     'Seventh entry in the slasher franchise, bringing a masked killer back to a small town two decades later.',
     'Horror Sequel', 'completed',
     'Atlanta, GA', ST_SetSRID(ST_MakePoint(-84.4277, 33.7756), 4326)::geography, '2025-09-01', '2025-11-15'),

    ('Tiny Troublemakers & Monsters',
     'Animated crossover pairing mischievous yellow henchmen with a houseful of lovable movie monsters.',
     'Animated Crossover', 'active',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2851, 34.0975), 4326)::geography, '2026-06-01', NULL),

    ('Stormcliff Manor',
     'Period drama set on the windswept English moors, tracing a doomed, obsessive romance across two families.',
     'Period Drama', 'completed',
     'London, UK', ST_SetSRID(ST_MakePoint(-0.1278, 51.5074), 4326)::geography, '2025-01-05', '2025-06-30'),

    ('World Beyond: Embers Rising',
     'Sci-fi epic returning to a lush alien world as its clans unite against an encroaching industrial threat.',
     'Sci-Fi Epic', 'planning',
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2004, 34.0522), 4326)::geography, '2027-06-01', NULL);

-- ---------------------------------------------------------------------------
-- project_members: rosters (role_tag_id-backed)
-- ---------------------------------------------------------------------------
INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Web Slinger: Brand New Dawn' AND (e.name, t.label) IN (
    ('Lena Okafor', 'Director'),
    ('Maya Chen', 'Director of Photography'),
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Marcus Webb', 'Stunt Coordinator'),
    ('Jasmine Cole', 'Stunt Performer'),
    ('Grace Liu', 'Unit Production Manager')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Moonwalker: A Life in Rhythm' AND (e.name, t.label) IN (
    ('Lena Okafor', 'Director'),
    ('Julian Osei', 'Composer'),
    ('Renee Castillo', 'Music Supervisor'),
    ('Elena Marchetti', 'Costume Designer'),
    ('Dominique Price', 'Key Hair Stylist'),
    ('Farrah Simmons', 'Key Makeup Artist'),
    ('Miles Tran', 'Boom Operator')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Starlight Plumbers: Galactic Leap' AND (e.name, t.label) IN (
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Ava Lindqvist', 'Compositor'),
    ('Renee Castillo', 'Music Supervisor'),
    ('Harold Finnegan', 'Casting Director')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Playroom Pals 5' AND (e.name, t.label) IN (
    ('Ava Lindqvist', 'Compositor'),
    ('Julian Osei', 'Composer'),
    ('Grace Liu', 'Unit Production Manager')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'The Long Voyage Home' AND (e.name, t.label) IN (
    ('Lena Okafor', 'Director'),
    ('Noah Kessler', 'Production Designer'),
    ('Liam Forsythe', 'Gaffer'),
    ('Sofia Delgado', 'Camera Operator'),
    ('Celia Dunmore', 'Location Manager')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Last Light Protocol' AND (e.name, t.label) IN (
    ('Maya Chen', 'Director of Photography'),
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Owen Baptiste', 'Script Supervisor'),
    ('Anjali Deshmukh', 'Sound Designer')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Shriek VII' AND (e.name, t.label) IN (
    ('Marcus Webb', 'Stunt Coordinator'),
    ('Victor Hale', 'SFX Makeup Artist'),
    ('Devon Marsh', 'Sound Mixer'),
    ('Jorge Alvarez', 'Gaffer')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Tiny Troublemakers & Monsters' AND (e.name, t.label) IN (
    ('Ava Lindqvist', 'Compositor'),
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Renee Castillo', 'Music Supervisor')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'Stormcliff Manor' AND (e.name, t.label) IN (
    ('Elena Marchetti', 'Costume Designer'),
    ('Noah Kessler', 'Production Designer'),
    ('Ruth Alvarado', 'Set Decorator'),
    ('Owen Baptiste', 'Script Supervisor'),
    ('Harold Finnegan', 'Casting Director')
);

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id FROM projects p, entities e, tags t
WHERE p.name = 'World Beyond: Embers Rising' AND (e.name, t.label) IN (
    ('Lena Okafor', 'Director'),
    ('Maya Chen', 'Director of Photography'),
    ('Theo Bramwell', 'Visual Effects Supervisor'),
    ('Grace Liu', 'Unit Production Manager'),
    ('Celia Dunmore', 'Location Manager')
);

-- ---------------------------------------------------------------------------
-- project_members: the 2 business vendors (role_free_text — no single
-- controlled tag fits "vendor relationship", same hybrid pattern as the
-- original seed's 'Aerial Operator' free-text role)
-- ---------------------------------------------------------------------------
INSERT INTO project_members (project_id, entity_id, role_free_text)
SELECT p.id, e.id, 'Post-Production Vendor'
FROM projects p, entities e
WHERE p.name IN ('Web Slinger: Brand New Dawn', 'Last Light Protocol') AND e.name = 'Northstar Post & VFX';

INSERT INTO project_members (project_id, entity_id, role_free_text)
SELECT p.id, e.id, 'Premiere Event Producer'
FROM projects p, entities e
WHERE p.name = 'Web Slinger: Brand New Dawn' AND e.name = 'Bright Spark Premiere Events';
