-- KBFA Production Connect — taxonomy expansion
-- Researched against IMDb's professional credit categories (45 categories as
-- of its Nov 2025 update: https://help.imdb.com/article/contribution/filmography-credits/new-credit-categories/GVX4ZP2JX4W5QWAN)
-- and StudioBinder's film crew position guide
-- (https://www.studiobinder.com/blog/film-crew-positions/), then extended with
-- live-event/broadcast roles and equipment to match this project's stated
-- scope (film/video/events, not film-only). See the README's "Taxonomy
-- expansion" section for how this was researched and how to extend it again.
--
-- Idempotent: every INSERT targets the existing unique constraints
-- (tags: (tag_type, lower(label)); entity_types: code) with ON CONFLICT DO
-- NOTHING, so this file can be re-run safely (e.g. against a freshly
-- rebuilt dev database) without duplicating rows or erroring on a second run.
--
-- Deliberately does NOT touch the sample data in db/seed/001_sample_data.sql
-- or assign any of these new tags to the sample entities — this is taxonomy
-- (the controlled vocabulary itself), not seed data.

-- ---------------------------------------------------------------------------
-- Normalize 3 pre-existing tags' `category` values to the broader
-- department names used throughout this file, so the taxonomy groups
-- consistently (e.g. in a category-grouped facet picker) instead of
-- splitting "Gaffer" (category 'Lighting') away from the new granular
-- lighting-crew tags (category 'Grip & Electric'). Labels/aliases
-- untouched — category only. Idempotent (no-ops once applied).
-- ---------------------------------------------------------------------------
UPDATE tags SET category = 'Grip & Electric' WHERE tag_type = 'skill' AND label = 'Gaffer' AND category = 'Lighting';
UPDATE tags SET category = 'Grip & Electric' WHERE tag_type = 'skill' AND label = 'Key Grip' AND category = 'Grip';
UPDATE tags SET category = 'Sound Department' WHERE tag_type = 'skill' AND label = 'Sound Mixer' AND category = 'Sound';

-- ---------------------------------------------------------------------------
-- entity_types: a few granular business sub-categories the original seven
-- didn't cover (post-production, talent representation, live events, and
-- the agencies that commission production work) — all additive, no changes
-- to the existing seven rows.
-- ---------------------------------------------------------------------------
INSERT INTO entity_types (kind, code, label, description) VALUES
    ('business', 'post_house',         'Post-Production House',        'Editorial, VFX, color, and finishing services'),
    ('business', 'talent_agency',      'Talent / Casting Agency',      'Represents talent or provides casting services'),
    ('business', 'event_production_co','Event Production Company',     'Live event, experiential, or broadcast production company'),
    ('business', 'ad_agency',          'Advertising / Creative Agency','Agency commissioning or creative-directing production work')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- tags: skill-type — granular crew competencies, by department.
-- Existing skill tags (DP, Gaffer, Key Grip, Drone Pilot, Sound Mixer,
-- Editor, Colorist, Line Producer, 1st Assistant Director, Hair & Makeup
-- Artist) are left untouched; nothing below duplicates those labels.
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    -- Camera Department
    ('skill', 'Camera Operator',            'Camera Department', ARRAY['Cam Op']),
    ('skill', '1st Assistant Camera',       'Camera Department', ARRAY['1st AC', 'Focus Puller']),
    ('skill', '2nd Assistant Camera',       'Camera Department', ARRAY['2nd AC', 'Clapper Loader']),
    ('skill', 'Digital Imaging Technician', 'Camera Department', ARRAY['DIT']),
    ('skill', 'Steadicam Operator',         'Camera Department', ARRAY['Steadicam']),
    ('skill', 'Gimbal Operator',            'Camera Department', ARRAY['Ronin Operator']),
    ('skill', 'Underwater Camera Operator', 'Camera Department', ARRAY['Underwater DP']),
    ('skill', 'Motion Control Operator',    'Camera Department', ARRAY['Moco Operator']),
    ('skill', 'Film Loader',                'Camera Department', ARRAY[]::text[]),
    ('skill', 'Camera Utility',             'Camera Department', ARRAY['Camera PA']),
    ('skill', 'Unit Still Photographer',    'Camera Department', ARRAY['Unit Photographer', 'Set Photographer']),
    ('skill', 'Video Assist Operator',      'Camera Department', ARRAY['Video Assist', 'VTR Operator']),

    -- Grip & Electric
    ('skill', 'Best Boy Electric',   'Grip & Electric', ARRAY[]::text[]),
    ('skill', 'Lighting Technician', 'Grip & Electric', ARRAY['Electrician', 'Spark']),
    ('skill', 'Generator Operator',  'Grip & Electric', ARRAY['Genny Op']),
    ('skill', 'Best Boy Grip',       'Grip & Electric', ARRAY[]::text[]),
    ('skill', 'Dolly Grip',          'Grip & Electric', ARRAY[]::text[]),
    ('skill', 'Rigging Grip',        'Grip & Electric', ARRAY[]::text[]),
    ('skill', 'Rigging Gaffer',      'Grip & Electric', ARRAY[]::text[]),
    ('skill', 'Set Lighting Swing',  'Grip & Electric', ARRAY['Swing']),

    -- Sound Department
    ('skill', 'Boom Operator',       'Sound Department', ARRAY['Boom Op']),
    ('skill', 'Sound Utility',       'Sound Department', ARRAY['Cable Person']),
    ('skill', 'Sound Designer',      'Sound Department', ARRAY[]::text[]),
    ('skill', 'Foley Artist',        'Sound Department', ARRAY[]::text[]),
    ('skill', 'Foley Mixer',         'Sound Department', ARRAY[]::text[]),
    ('skill', 'ADR Mixer',           'Sound Department', ARRAY[]::text[]),
    ('skill', 'Re-Recording Mixer',  'Sound Department', ARRAY['Dubbing Mixer']),
    ('skill', 'Dialogue Editor',     'Sound Department', ARRAY[]::text[]),
    ('skill', 'Music Editor',        'Sound Department', ARRAY[]::text[]),

    -- Art Department
    ('skill', 'Production Designer',   'Art Department', ARRAY[]::text[]),
    ('skill', 'Art Director',          'Art Department', ARRAY[]::text[]),
    ('skill', 'Set Decorator',         'Art Department', ARRAY[]::text[]),
    ('skill', 'Set Dresser',           'Art Department', ARRAY[]::text[]),
    ('skill', 'Leadman',               'Art Department', ARRAY[]::text[]),
    ('skill', 'Scenic Artist',         'Art Department', ARRAY['Scenic Painter']),
    ('skill', 'Property Master',       'Art Department', ARRAY['Props Master']),
    ('skill', 'Props Builder',         'Art Department', ARRAY['Prop Maker']),
    ('skill', 'Construction Coordinator', 'Art Department', ARRAY[]::text[]),
    ('skill', 'Set Carpenter',         'Art Department', ARRAY['Carpenter']),
    ('skill', 'Greensman',             'Art Department', ARRAY[]::text[]),

    -- Costume & Wardrobe
    ('skill', 'Costume Designer',   'Costume & Wardrobe', ARRAY[]::text[]),
    ('skill', 'Costume Supervisor', 'Costume & Wardrobe', ARRAY[]::text[]),
    ('skill', 'Wardrobe Stylist',   'Costume & Wardrobe', ARRAY[]::text[]),
    ('skill', 'Set Costumer',       'Costume & Wardrobe', ARRAY['Set Costume PA']),
    ('skill', 'Costume Tailor',     'Costume & Wardrobe', ARRAY['Seamstress']),

    -- Hair & Makeup
    ('skill', 'Key Hair Stylist',  'Hair & Makeup', ARRAY[]::text[]),
    ('skill', 'Key Makeup Artist', 'Hair & Makeup', ARRAY[]::text[]),
    ('skill', 'SFX Makeup Artist', 'Hair & Makeup', ARRAY['Prosthetics Artist']),
    ('skill', 'Body Makeup Artist','Hair & Makeup', ARRAY[]::text[]),

    -- Production Management / Office
    ('skill', 'Unit Production Manager',   'Production Management', ARRAY['UPM']),
    ('skill', 'Production Supervisor',     'Production Management', ARRAY[]::text[]),
    ('skill', 'Script Supervisor',         'Production Management', ARRAY['Script Sup', 'Continuity']),
    ('skill', 'Set Production Assistant',  'Production Management', ARRAY['Set PA']),
    ('skill', 'Office Production Assistant','Production Management', ARRAY['Office PA']),
    ('skill', 'Production Accountant',     'Production Management', ARRAY[]::text[]),
    ('skill', 'Payroll Accountant',        'Production Management', ARRAY[]::text[]),

    -- Locations
    ('skill', 'Location Manager',           'Locations', ARRAY[]::text[]),
    ('skill', 'Location Scout',             'Locations', ARRAY[]::text[]),
    ('skill', 'Assistant Location Manager', 'Locations', ARRAY['ALM']),

    -- Transportation
    ('skill', 'Transportation Coordinator', 'Transportation', ARRAY[]::text[]),
    ('skill', 'Picture Car Coordinator',    'Transportation', ARRAY[]::text[]),
    ('skill', 'Production Driver',          'Transportation', ARRAY['Teamster']),

    -- Catering & Craft Service
    ('skill', 'Caterer',        'Catering & Craft Service', ARRAY[]::text[]),
    ('skill', 'Craft Service',  'Catering & Craft Service', ARRAY['Crafty']),

    -- Post-Production
    ('skill', 'Assistant Editor',               'Post-Production', ARRAY[]::text[]),
    ('skill', 'Post-Production Supervisor',     'Post-Production', ARRAY[]::text[]),
    ('skill', 'Online Editor',                  'Post-Production', ARRAY[]::text[]),
    ('skill', 'Digital Intermediate Supervisor','Post-Production', ARRAY['DI Supervisor']),

    -- VFX & Animation
    ('skill', 'Visual Effects Supervisor',   'VFX & Animation', ARRAY['VFX Supervisor']),
    ('skill', 'Visual Effects Producer',     'VFX & Animation', ARRAY['VFX Producer']),
    ('skill', 'Compositor',                  'VFX & Animation', ARRAY[]::text[]),
    ('skill', '3D Animator',                 'VFX & Animation', ARRAY['CG Animator']),
    ('skill', 'Motion Graphics Artist',      'VFX & Animation', ARRAY['Motion Designer']),
    ('skill', 'Rotoscope Artist',            'VFX & Animation', ARRAY['Roto Artist']),
    ('skill', 'Matte Painter',               'VFX & Animation', ARRAY[]::text[]),
    ('skill', 'Previsualization Artist',     'VFX & Animation', ARRAY['Previs Artist']),

    -- Stunts & Special Effects
    ('skill', 'Stunt Coordinator',           'Stunts & Special Effects', ARRAY[]::text[]),
    ('skill', 'Stunt Performer',             'Stunts & Special Effects', ARRAY['Stunt Double']),
    ('skill', 'Stunt Rigger',                'Stunts & Special Effects', ARRAY[]::text[]),
    ('skill', 'Special Effects Coordinator', 'Stunts & Special Effects', ARRAY['SFX Coordinator', 'Practical FX']),
    ('skill', 'Pyrotechnician',              'Stunts & Special Effects', ARRAY[]::text[]),
    ('skill', 'Armorer',                     'Stunts & Special Effects', ARRAY['Weapons Wrangler']),

    -- Casting
    ('skill', 'Casting Director', 'Casting', ARRAY[]::text[]),
    ('skill', 'Casting Associate','Casting', ARRAY[]::text[]),

    -- Music
    ('skill', 'Composer',       'Music', ARRAY[]::text[]),
    ('skill', 'Music Supervisor','Music', ARRAY[]::text[]),
    ('skill', 'Orchestrator',   'Music', ARRAY[]::text[]),
    ('skill', 'Scoring Mixer',  'Music', ARRAY['Music Mixer']),

    -- Choreography & Intimacy
    ('skill', 'Choreographer',         'Choreography & Intimacy', ARRAY[]::text[]),
    ('skill', 'Intimacy Coordinator',  'Choreography & Intimacy', ARRAY[]::text[]),
    ('skill', 'Fight Choreographer',   'Choreography & Intimacy', ARRAY['Fight Coordinator']),

    -- Puppetry
    ('skill', 'Puppeteer',          'Puppetry', ARRAY[]::text[]),
    ('skill', 'Puppet Fabricator',  'Puppetry', ARRAY[]::text[]),

    -- Publicity & Marketing
    ('skill', 'Unit Publicist',               'Publicity & Marketing', ARRAY[]::text[]),
    ('skill', 'EPK Producer',                 'Publicity & Marketing', ARRAY['Electronic Press Kit Producer']),
    ('skill', 'Social Media Content Producer','Publicity & Marketing', ARRAY[]::text[]),

    -- Legal & Finance
    ('skill', 'Entertainment Attorney',    'Legal & Finance', ARRAY['Production Counsel']),
    ('skill', 'Production Finance Manager','Legal & Finance', ARRAY[]::text[]),

    -- Medical & Safety
    ('skill', 'Set Medic',              'Medical & Safety', ARRAY['On-Set EMT']),
    ('skill', 'Health & Safety Officer','Medical & Safety', ARRAY['COVID Compliance Officer']),

    -- Live Events & Broadcast (the "events" half of this project's scope,
    -- not covered by a film-crew-only taxonomy)
    ('skill', 'Event Producer',               'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Event Planner',                'Live Events & Broadcast', ARRAY['Event Coordinator']),
    ('skill', 'Stage Manager',                'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Technical Director',           'Live Events & Broadcast', ARRAY['TD']),
    ('skill', 'Front of House Audio Engineer','Live Events & Broadcast', ARRAY['FOH Engineer']),
    ('skill', 'Monitor Engineer',             'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Live Event Lighting Designer', 'Live Events & Broadcast', ARRAY['LD']),
    ('skill', 'Broadcast Video Director',     'Live Events & Broadcast', ARRAY['Vision Mixer', 'Switcher']),
    ('skill', 'Broadcast Engineer',           'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Truss Rigger',                 'Live Events & Broadcast', ARRAY['Rigger']),
    ('skill', 'AV Technician',                'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Event Security Coordinator',   'Live Events & Broadcast', ARRAY[]::text[]),
    ('skill', 'Venue Coordinator',            'Live Events & Broadcast', ARRAY[]::text[])
ON CONFLICT (tag_type, lower(label)) DO NOTHING;

-- ---------------------------------------------------------------------------
-- tags: role-type — pure producing/directing titles (no specific craft
-- skill attached), extending the existing three (Director, Producer,
-- Production Coordinator). Reserved for project_members.role_tag_id use;
-- any skill-type tag above can still be used as a project role too (the
-- schema places no CHECK on role_tag_id's tag_type).
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    ('role', 'Executive Producer',        'Production Role', ARRAY['EP']),
    ('role', 'Co-Producer',               'Production Role', ARRAY[]::text[]),
    ('role', 'Associate Producer',        'Production Role', ARRAY['AP']),
    ('role', 'Supervising Producer',      'Production Role', ARRAY[]::text[]),
    ('role', 'Showrunner',                'Production Role', ARRAY[]::text[]),
    ('role', '2nd Assistant Director',    'Production Role', ARRAY['2nd AD']),
    ('role', '2nd 2nd Assistant Director','Production Role', ARRAY['2nd 2nd AD']),
    ('role', 'Creative Director',         'Production Role', ARRAY[]::text[]),
    ('role', 'Second Unit Director',      'Production Role', ARRAY[]::text[])
ON CONFLICT (tag_type, lower(label)) DO NOTHING;

-- ---------------------------------------------------------------------------
-- tags: equipment-type — camera bodies, lenses, lighting, grip, camera
-- support, drones, sound gear, power, live-event AV, and post-production
-- equipment. Existing equipment tags (RED Komodo 6K, ARRI Alexa Mini LF,
-- Sony FX9, DJI Inspire 3, Chapman Hybrid Dolly, ARRI SkyPanel S60, 12x12
-- Butterfly/Overhead Kit) are left untouched.
-- ---------------------------------------------------------------------------
INSERT INTO tags (tag_type, label, category, aliases) VALUES
    -- Camera bodies
    ('equipment', 'ARRI Alexa 35',                   'Camera', ARRAY['Alexa 35']),
    ('equipment', 'ARRI Alexa 65',                   'Camera', ARRAY['Alexa 65']),
    ('equipment', 'RED V-Raptor 8K VV',               'Camera', ARRAY['V-Raptor']),
    ('equipment', 'Sony Venice 2',                    'Camera', ARRAY['Venice 2']),
    ('equipment', 'Sony FX6',                         'Camera', ARRAY['FX6']),
    ('equipment', 'Canon C300 Mark III',              'Camera', ARRAY['C300 Mark III']),
    ('equipment', 'Blackmagic URSA Mini Pro 12K',     'Camera', ARRAY['URSA Mini Pro 12K']),
    ('equipment', 'IMAX Camera',                      'Camera', ARRAY[]::text[]),

    -- Lenses
    ('equipment', 'ARRI Signature Prime Set',  'Lenses', ARRAY['Signature Primes']),
    ('equipment', 'Zeiss Supreme Prime Set',   'Lenses', ARRAY['Supreme Primes']),
    ('equipment', 'Angenieux Optimo Zoom',     'Lenses', ARRAY['Optimo Zoom']),
    ('equipment', 'Cooke S4/i Prime Set',      'Lenses', ARRAY['Cooke S4i']),
    ('equipment', 'Anamorphic Lens Set',       'Lenses', ARRAY['Anamorphics']),

    -- Lighting
    ('equipment', 'ARRI SkyPanel S360',  'Lighting', ARRAY['SkyPanel S360']),
    ('equipment', 'Astera Titan Tube',   'Lighting', ARRAY['Titan Tube']),
    ('equipment', 'Aputure 1200D',       'Lighting', ARRAY[]::text[]),
    ('equipment', 'Kino Flo Diva-Lite',  'Lighting', ARRAY['Diva-Lite']),
    ('equipment', 'HMI 18K Fresnel',     'Lighting', ARRAY['18K HMI']),
    ('equipment', 'LED Fresnel Kit',     'Lighting', ARRAY[]::text[]),
    ('equipment', 'Dedolight Kit',       'Lighting', ARRAY[]::text[]),

    -- Grip
    ('equipment', 'Fisher 11 Dolly',       'Grip', ARRAY['Fisher Dolly']),
    ('equipment', 'Technocrane',           'Grip', ARRAY[]::text[]),
    ('equipment', 'Jib Arm',               'Grip', ARRAY[]::text[]),
    ('equipment', 'C-Stand Package',       'Grip', ARRAY['C-Stands']),
    ('equipment', 'Apple Box Set',         'Grip', ARRAY['Apple Boxes']),
    ('equipment', 'Combo Stand Package',   'Grip', ARRAY[]::text[]),

    -- Camera support
    ('equipment', 'DJI Ronin 2 Gimbal', 'Camera Support', ARRAY['Ronin 2']),
    ('equipment', 'Steadicam Rig',      'Camera Support', ARRAY[]::text[]),
    ('equipment', 'Easyrig',            'Camera Support', ARRAY[]::text[]),

    -- Drone / aerial
    ('equipment', 'DJI Mavic 3 Pro',   'Drone', ARRAY['Mavic 3 Pro']),
    ('equipment', 'FreeFly Alta X',    'Drone', ARRAY['Alta X Cinema Drone']),

    -- Sound equipment
    ('equipment', 'Sound Devices Scorpio Recorder',   'Sound Equipment', ARRAY['Scorpio Recorder']),
    ('equipment', 'Sennheiser MKH 416 Shotgun Mic',   'Sound Equipment', ARRAY['MKH 416']),
    ('equipment', 'Lectrosonics Wireless Lav System', 'Sound Equipment', ARRAY['Lectro Wireless']),
    ('equipment', 'Zoom H6 Recorder',                 'Sound Equipment', ARRAY['H6 Recorder']),

    -- Power & distribution
    ('equipment', 'Honda EU7000is Generator', 'Power & Distribution', ARRAY['Honda Generator']),
    ('equipment', 'Cable & Distro Package',   'Power & Distribution', ARRAY['Distro Box']),

    -- Live event AV equipment
    ('equipment', 'LED Video Wall',              'Event AV Equipment', ARRAY[]::text[]),
    ('equipment', 'Line Array PA System',        'Event AV Equipment', ARRAY['Line Array']),
    ('equipment', 'Digital Mixing Console',      'Event AV Equipment', ARRAY['Front of House Console']),
    ('equipment', 'Moving Head Light Fixture',   'Event AV Equipment', ARRAY['Moving Head']),
    ('equipment', 'Projection Mapping System',   'Event AV Equipment', ARRAY['Projector Package']),
    ('equipment', 'Trussing & Rigging System',   'Event AV Equipment', ARRAY['Truss System']),

    -- Post-production equipment
    ('equipment', 'DaVinci Resolve Suite',       'Post-Production Equipment', ARRAY['Resolve Suite']),
    ('equipment', 'Avid Media Composer Suite',   'Post-Production Equipment', ARRAY['Avid Suite']),
    ('equipment', 'Color Grading Control Panel', 'Post-Production Equipment', ARRAY['Tangent Panel'])
ON CONFLICT (tag_type, lower(label)) DO NOTHING;
