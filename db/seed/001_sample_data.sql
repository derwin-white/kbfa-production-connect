-- Sample data for prototyping faceted search. Not production seed data.
-- Covers: individuals + businesses, controlled tags w/ aliases, free-text
-- overflow skills, locations around NYC/LA/Atlanta for proximity testing,
-- a handful of connections, and two projects with members.

-- ---------------------------------------------------------------------------
-- Controlled vocabulary tags
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    ('skill', 'Director of Photography', 'Camera Department', ARRAY['DP', 'DoP', 'Cinematographer']),
    ('skill', 'Gaffer', 'Lighting', ARRAY['Chief Lighting Technician', 'CLT']),
    ('skill', 'Key Grip', 'Grip', ARRAY['Grip Lead']),
    ('skill', 'Drone Pilot', 'Camera Department', ARRAY['UAV Operator', 'Part 107 Pilot']),
    ('skill', 'Sound Mixer', 'Sound', ARRAY['Production Sound Mixer', 'PSM']),
    ('skill', 'Editor', 'Post-Production', ARRAY['Video Editor']),
    ('skill', 'Colorist', 'Post-Production', ARRAY['Color Grading Artist']),
    ('skill', 'Line Producer', 'Production Management', ARRAY['LP']),
    ('skill', '1st Assistant Director', 'Production Management', ARRAY['1st AD', 'First AD']),
    ('skill', 'Hair & Makeup Artist', 'Hair & Makeup', ARRAY['HMU', 'MUA']),
    ('equipment', 'RED Komodo 6K', 'Camera', ARRAY['Komodo', 'RED Komodo']),
    ('equipment', 'ARRI Alexa Mini LF', 'Camera', ARRAY['Alexa Mini LF', 'ArriMini']),
    ('equipment', 'Sony FX9', 'Camera', ARRAY['FX9']),
    ('equipment', 'DJI Inspire 3', 'Drone', ARRAY['Inspire 3']),
    ('equipment', 'Chapman Hybrid Dolly', 'Grip', ARRAY['Hybrid Dolly']),
    ('equipment', 'ARRI SkyPanel S60', 'Lighting', ARRAY['SkyPanel S60']),
    ('equipment', '12x12 Butterfly/Overhead Kit', 'Grip', ARRAY['12x12 Butterfly']),
    ('role', 'Director', 'Production Role', ARRAY[]::text[]),
    ('role', 'Producer', 'Production Role', ARRAY[]::text[]),
    ('role', 'Production Coordinator', 'Production Role', ARRAY['PC']);

-- ---------------------------------------------------------------------------
-- Entities (individuals)
-- ---------------------------------------------------------------------------
INSERT INTO entities (entity_type_id, name, headline, bio, contact, free_text_skills, location_label, location, metadata)
VALUES
    ((SELECT id FROM entity_types WHERE code='creative'),
     'Maya Chen', 'Director of Photography — Brooklyn, NY',
     'DP with 10 years shooting commercials and docs across the Northeast. Owns a RED Komodo package.',
     '{"email":"maya.chen@example.com","website":"mayachendp.com","imdb":"nm1234567"}',
     ARRAY['underwater housing operation', 'Steadicam'],
     'Brooklyn, NY', ST_SetSRID(ST_MakePoint(-73.9442, 40.6782), 4326)::geography,
     '{"union": "IATSE 600", "day_rate_usd": 1200}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Jorge Alvarez', 'Gaffer / Lighting Tech — Queens, NY',
     'Gaffer specializing in commercial and music video lighting. Full SkyPanel kit.',
     '{"email":"jorge.alvarez@example.com","phone":"+1-718-555-0110"}',
     ARRAY['generator operation'],
     'Queens, NY', ST_SetSRID(ST_MakePoint(-73.7949, 40.7282), 4326)::geography,
     '{"union": "IATSE 52"}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Priya Natarajan', 'FAA Part 107 Drone Pilot — Jersey City, NJ',
     'Licensed drone pilot, DJI Inspire 3 owner-operator, real estate and event aerials.',
     '{"email":"priya.n@example.com"}',
     ARRAY['FPV flying', 'cinematic drone editing'],
     'Jersey City, NJ', ST_SetSRID(ST_MakePoint(-74.0431, 40.7178), 4326)::geography,
     '{"faa_part_107": true}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Devon Marsh', 'Production Sound Mixer — Atlanta, GA',
     'Boom + mixing for narrative and branded content across the Southeast.',
     '{"email":"devon.marsh@example.com"}',
     ARRAY['wireless lav systems', 'field recording'],
     'Atlanta, GA', ST_SetSRID(ST_MakePoint(-84.3880, 33.7490), 4326)::geography,
     '{}'),

    ((SELECT id FROM entity_types WHERE code='creative'),
     'Lena Okafor', 'Director — Los Angeles, CA',
     'Commercial and branded-content director, previously agency-side CD.',
     '{"email":"lena.okafor@example.com","website":"lenaokafor.com"}',
     ARRAY['storyboarding', 'talent coaching'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326)::geography,
     '{}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Sam Whitfield', '1st AD — Los Angeles, CA',
     'First AD on 30+ commercial and branded shoots, strong scheduling background.',
     '{"email":"sam.whitfield@example.com"}',
     ARRAY['union call sheets'],
     'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.3287, 34.0928), 4326)::geography,
     '{"union": "DGA"}'),

    ((SELECT id FROM entity_types WHERE code='crew'),
     'Ines Fontaine', 'Colorist / Editor — Brooklyn, NY',
     'DaVinci Resolve colorist and offline editor, music video + commercial background.',
     '{"email":"ines.fontaine@example.com"}',
     ARRAY['DaVinci Resolve', 'Premiere Pro'],
     'Brooklyn, NY', ST_SetSRID(ST_MakePoint(-73.9584, 40.6872), 4326)::geography,
     '{}');

-- ---------------------------------------------------------------------------
-- Entities (businesses)
-- ---------------------------------------------------------------------------
INSERT INTO entities (entity_type_id, name, headline, bio, contact, free_text_skills, location_label, location, metadata)
VALUES
    ((SELECT id FROM entity_types WHERE code='rental_house'),
     'Gothamwood Camera & Lighting', 'Camera/Grip/Lighting Rental — Long Island City, NY',
     'Full-service camera, grip, and lighting rental house serving the NYC metro area.',
     '{"email":"bookings@gothamwoodrental.example.com","phone":"+1-718-555-0199"}',
     ARRAY['same-day delivery', 'tech support on set'],
     'Long Island City, NY', ST_SetSRID(ST_MakePoint(-73.9485, 40.7447), 4326)::geography,
     '{}'),

    ((SELECT id FROM entity_types WHERE code='production_co'),
     'Lower East Pictures', 'Full-Service Production Company — Manhattan, NY',
     'Boutique production company producing commercials and branded content.',
     '{"email":"info@lowereastpictures.example.com","website":"lowereastpictures.example.com"}',
     ARRAY['end-to-end production', 'casting'],
     'Manhattan, NY', ST_SetSRID(ST_MakePoint(-73.9876, 40.7209), 4326)::geography,
     '{}'),

    ((SELECT id FROM entity_types WHERE code='studio'),
     'Harborlight Stages', 'Soundstage & Studio Space — Long Beach, CA',
     '3 soundstages, cyc wall, full grip package available on-site.',
     '{"email":"stages@harborlight.example.com"}',
     ARRAY['cyc wall', 'green room', 'parking for 40 vehicles'],
     'Long Beach, CA', ST_SetSRID(ST_MakePoint(-118.1937, 33.7701), 4326)::geography,
     '{}');

-- ---------------------------------------------------------------------------
-- entity_tags: controlled skill/equipment/role assignments
-- ---------------------------------------------------------------------------
INSERT INTO entity_tags (entity_id, tag_id)
SELECT e.id, t.id FROM entities e, tags t
WHERE (e.name, t.label) IN (
    ('Maya Chen', 'Director of Photography'),
    ('Maya Chen', 'RED Komodo 6K'),
    ('Maya Chen', 'ARRI Alexa Mini LF'),
    ('Jorge Alvarez', 'Gaffer'),
    ('Jorge Alvarez', 'ARRI SkyPanel S60'),
    ('Priya Natarajan', 'Drone Pilot'),
    ('Priya Natarajan', 'DJI Inspire 3'),
    ('Devon Marsh', 'Sound Mixer'),
    ('Lena Okafor', 'Director'),
    ('Sam Whitfield', '1st Assistant Director'),
    ('Ines Fontaine', 'Colorist'),
    ('Ines Fontaine', 'Editor'),
    ('Gothamwood Camera & Lighting', 'RED Komodo 6K'),
    ('Gothamwood Camera & Lighting', 'ARRI Alexa Mini LF'),
    ('Gothamwood Camera & Lighting', 'ARRI SkyPanel S60'),
    ('Gothamwood Camera & Lighting', 'Chapman Hybrid Dolly'),
    ('Lower East Pictures', 'Producer'),
    ('Harborlight Stages', '12x12 Butterfly/Overhead Kit')
);

-- ---------------------------------------------------------------------------
-- Connections
-- ---------------------------------------------------------------------------
INSERT INTO connections (requester_entity_id, recipient_entity_id, status, responded_at)
SELECT a.id, b.id, 'accepted', now()
FROM entities a, entities b
WHERE (a.name, b.name) IN (
    ('Maya Chen', 'Jorge Alvarez'),
    ('Maya Chen', 'Ines Fontaine'),
    ('Lena Okafor', 'Maya Chen'),
    ('Lena Okafor', 'Sam Whitfield')
);

INSERT INTO connections (requester_entity_id, recipient_entity_id, status)
SELECT a.id, b.id, 'pending'
FROM entities a, entities b
WHERE (a.name, b.name) IN (
    ('Priya Natarajan', 'Maya Chen')
);

-- ---------------------------------------------------------------------------
-- Projects + members
-- ---------------------------------------------------------------------------
INSERT INTO projects (owner_entity_id, name, description, project_type, status, location_label, location, start_date, end_date)
SELECT id, 'Northside Sneaker Co. — Fall Campaign', 'Three-day commercial shoot in Brooklyn.', 'Commercial', 'completed',
       'Brooklyn, NY', ST_SetSRID(ST_MakePoint(-73.9442, 40.6782), 4326)::geography, '2026-09-10', '2026-09-12'
FROM entities WHERE name = 'Lower East Pictures';

INSERT INTO project_members (project_id, entity_id, role_tag_id)
SELECT p.id, e.id, t.id
FROM projects p, entities e, tags t
WHERE p.name = 'Northside Sneaker Co. — Fall Campaign'
  AND (e.name, t.label) IN (
    ('Maya Chen', 'Director of Photography'),
    ('Jorge Alvarez', 'Gaffer'),
    ('Ines Fontaine', 'Colorist')
  );

INSERT INTO projects (owner_entity_id, name, description, project_type, status, location_label, location, start_date, end_date)
SELECT id, 'Pacific Realty Aerial Package', 'Drone + ground coverage for luxury listings.', 'Real Estate', 'active',
       'Los Angeles, CA', ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326)::geography, '2026-11-01', NULL
FROM entities WHERE name = 'Lena Okafor';

INSERT INTO project_members (project_id, entity_id, role_free_text)
SELECT p.id, e.id, 'Aerial Operator'
FROM projects p, entities e
WHERE p.name = 'Pacific Realty Aerial Package' AND e.name = 'Priya Natarajan';
