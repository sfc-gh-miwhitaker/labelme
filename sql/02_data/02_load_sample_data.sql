/*
 * LabelMe Demo - Sample Data Generation
 * Author: SE Community
 * Purpose: Generate synthetic dirty data for demo
 * Expires: 2026-01-16
 * 
 * Prerequisites: RAW tables exist
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- TEMPORARY LOOKUP TABLES FOR DATA GENERATION
-- ============================================================================

-- Artist name pools with intentional quality issues
CREATE OR REPLACE TEMPORARY TABLE artist_pool AS
SELECT column1 as dirty_name, column2 as correct_name, column3 as country_dirty, column4 as genre_dirty
FROM VALUES
    ('Bettles', 'Beatles', 'United Kingdom', 'ROCK'),
    ('TAYLOR swift', 'Taylor Swift', 'USA', 'pop music'),
    ('ed SHEERAN', 'Ed Sheeran', 'UK', 'Pop'),
    ('Qeen', 'Queen', 'United Kingdom', 'rock'),
    ('coldpley', 'Coldplay', 'U.K.', 'Alternative'),
    ('ADELL', 'Adele', 'United Kingdom', 'POP'),
    ('drake', 'Drake', 'canada', 'Hip Hop'),
    ('Rianna', 'Rihanna', 'Barbados', 'r&b'),
    ('beyonce', 'Beyonce', 'United States of America', 'R&B'),
    ('Bruno MARS', 'Bruno Mars', 'USA', 'Pop/R&B'),
    ('lady GAGA', 'Lady Gaga', 'United States', 'pop'),
    ('Justin BEIBER', 'Justin Bieber', 'Canada', 'POP'),
    ('Arianna Grande', 'Ariana Grande', 'US', 'pop'),
    ('THE weeknd', 'The Weeknd', 'canada', 'R&B'),
    ('Dua LIPA', 'Dua Lipa', 'united kingdom', 'Pop'),
    ('post malone', 'Post Malone', 'USA', 'hip hop'),
    ('BTS', 'BTS', 'South Korea', 'K-POP'),
    ('BLACKPINK', 'BLACKPINK', 'korea', 'K-Pop'),
    ('Bad BUNNY', 'Bad Bunny', 'Puerto Rico', 'reggaeton'),
    ('Shakria', 'Shakira', 'Colombia', 'Latin Pop')
;

-- Non-English song titles for translation demo
CREATE OR REPLACE TEMPORARY TABLE foreign_songs AS
SELECT column1 as title_foreign, column2 as language_code, column3 as title_english
FROM VALUES
    ('Despacito', 'es', 'Slowly'),
    ('La Vie en Rose', 'fr', 'Life in Pink'),
    ('99 Luftballons', 'de', '99 Red Balloons'),
    ('Gangnam Style', 'ko', 'Gangnam Style'),
    ('Con Calma', 'es', 'Calmly'),
    ('Bailando', 'es', 'Dancing'),
    ('La Bamba', 'es', 'The Bamba'),
    ('Volare', 'it', 'To Fly'),
    ('Macarena', 'es', 'Macarena'),
    ('Dragostea Din Tei', 'ro', 'Love from the Linden Trees')
;

-- Platform name variations
CREATE OR REPLACE TEMPORARY TABLE platform_variations AS
SELECT column1 as dirty_platform, column2 as clean_platform
FROM VALUES
    ('Spotify', 'Spotify'),
    ('SPOTIFY', 'Spotify'),
    ('spotify', 'Spotify'),
    ('Apple Music', 'Apple Music'),
    ('APPLE MUSIC', 'Apple Music'),
    ('apple music', 'Apple Music'),
    ('Amazon Music', 'Amazon Music'),
    ('AMAZON', 'Amazon Music'),
    ('YouTube Music', 'YouTube Music'),
    ('youtube', 'YouTube Music'),
    ('Tidal', 'Tidal'),
    ('TIDAL', 'Tidal'),
    ('Deezer', 'Deezer'),
    ('deezer', 'Deezer'),
    ('Pandora', 'Pandora'),
    ('PANDORA', 'Pandora')
;

-- Region name variations  
CREATE OR REPLACE TEMPORARY TABLE region_variations AS
SELECT column1 as dirty_region, column2 as clean_code
FROM VALUES
    ('USA', 'US'),
    ('United States', 'US'),
    ('United States of America', 'US'),
    ('U.S.A.', 'US'),
    ('United Kingdom', 'GB'),
    ('UK', 'GB'),
    ('U.K.', 'GB'),
    ('Great Britain', 'GB'),
    ('Canada', 'CA'),
    ('canada', 'CA'),
    ('Germany', 'DE'),
    ('deutschland', 'DE'),
    ('France', 'FR'),
    ('france', 'FR'),
    ('Japan', 'JP'),
    ('japan', 'JP'),
    ('Australia', 'AU'),
    ('australia', 'AU'),
    ('Brazil', 'BR'),
    ('brasil', 'BR'),
    ('Mexico', 'MX'),
    ('mexico', 'MX'),
    ('Spain', 'ES'),
    ('espana', 'ES')
;

-- ============================================================================
-- INSERT ARTISTS (500 records)
-- ============================================================================
INSERT INTO RAW_ARTISTS 
(artist_id, artist_name, country_of_origin, genre_primary, genre_secondary, label_signed_date, contract_end_date, social_followers, monthly_listeners)
WITH numbered_artists AS (
    SELECT 
        dirty_name, correct_name, country_dirty, genre_dirty,
        ROW_NUMBER() OVER (ORDER BY dirty_name) as rn
    FROM artist_pool
),
numbered_regions AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) as rn
    FROM region_variations
),
base_data AS (
    SELECT SEQ4() + 1 as id FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT 
    b.id as artist_id,
    CASE 
        WHEN RANDOM() < 0.3 THEN a.dirty_name
        WHEN RANDOM() < 0.6 THEN UPPER(a.correct_name)
        ELSE LOWER(a.correct_name)
    END as artist_name,
    CASE 
        WHEN RANDOM() < 0.5 THEN a.country_dirty
        ELSE r.dirty_region
    END as country_of_origin,
    a.genre_dirty as genre_primary,
    CASE WHEN RANDOM() < 0.3 THEN 'electronic' ELSE NULL END as genre_secondary,
    DATEADD('day', -FLOOR(RANDOM() * 3650), CURRENT_DATE()) as label_signed_date,
    DATEADD('day', FLOOR(RANDOM() * 1825), CURRENT_DATE()) as contract_end_date,
    FLOOR(RANDOM() * 50000000) as social_followers,
    FLOOR(RANDOM() * 100000000) as monthly_listeners
FROM base_data b
JOIN numbered_artists a ON MOD(b.id - 1, 20) + 1 = a.rn
JOIN numbered_regions r ON MOD(b.id - 1, 22) + 1 = r.rn;

-- ============================================================================
-- INSERT ALBUMS (1500 records)
-- ============================================================================
INSERT INTO RAW_ALBUMS
(album_id, artist_id, album_title, release_date, album_type, genre, total_tracks, label_name, distribution_region)
WITH numbered_songs AS (
    SELECT title_foreign, ROW_NUMBER() OVER (ORDER BY title_foreign) as rn
    FROM foreign_songs
),
numbered_regions AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) as rn
    FROM region_variations
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY a.artist_id, RANDOM()) as album_id,
    a.artist_id,
    CASE 
        WHEN RANDOM() < 0.2 THEN f.title_foreign
        WHEN RANDOM() < 0.5 THEN UPPER('Album ' || FLOOR(RANDOM() * 100)::VARCHAR)
        ELSE 'album ' || FLOOR(RANDOM() * 100)::VARCHAR
    END as album_title,
    DATEADD('day', -FLOOR(RANDOM() * 3650), CURRENT_DATE()) as release_date,
    CASE FLOOR(RANDOM() * 4)
        WHEN 0 THEN 'LP'
        WHEN 1 THEN 'Album'
        WHEN 2 THEN 'Full Length'
        ELSE 'EP'
    END as album_type,
    a.genre_primary as genre,
    FLOOR(RANDOM() * 15) + 5 as total_tracks,
    CASE FLOOR(RANDOM() * 5)
        WHEN 0 THEN 'Universal'
        WHEN 1 THEN 'UNIVERSAL MUSIC'
        WHEN 2 THEN 'Sony Music'
        WHEN 3 THEN 'SONY'
        ELSE 'Warner Music Group'
    END as label_name,
    r.dirty_region as distribution_region
FROM RAW_ARTISTS a
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 3))
JOIN numbered_songs f ON MOD(a.artist_id - 1, 10) + 1 = f.rn
JOIN numbered_regions r ON MOD(a.artist_id - 1, 22) + 1 = r.rn
LIMIT 1500;

-- ============================================================================
-- INSERT SONGS (5000 records)
-- ============================================================================
INSERT INTO RAW_SONGS
(song_id, album_id, artist_id, song_title, duration_seconds, is_explicit, language_original, featuring_artists, isrc_code, track_number)
WITH numbered_songs AS (
    SELECT title_foreign, language_code, ROW_NUMBER() OVER (ORDER BY title_foreign) as rn
    FROM foreign_songs
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY al.album_id, RANDOM()) as song_id,
    al.album_id,
    al.artist_id,
    CASE 
        WHEN RANDOM() < 0.15 THEN f.title_foreign
        WHEN RANDOM() < 0.4 THEN UPPER('Track ' || FLOOR(RANDOM() * 1000)::VARCHAR)
        ELSE 'track ' || FLOOR(RANDOM() * 1000)::VARCHAR
    END as song_title,
    FLOOR(RANDOM() * 180) + 120 as duration_seconds,
    RANDOM() < 0.15 as is_explicit,
    CASE 
        WHEN RANDOM() < 0.15 THEN f.language_code
        ELSE 'en'
    END as language_original,
    CASE FLOOR(RANDOM() * 4)
        WHEN 0 THEN NULL
        WHEN 1 THEN 'feat. Artist ' || FLOOR(RANDOM() * 100)::VARCHAR
        WHEN 2 THEN 'ft. Artist ' || FLOOR(RANDOM() * 100)::VARCHAR
        ELSE 'featuring Artist ' || FLOOR(RANDOM() * 100)::VARCHAR
    END as featuring_artists,
    'US' || LPAD(FLOOR(RANDOM() * 1000000000)::VARCHAR, 9, '0') as isrc_code,
    MOD(ROW_NUMBER() OVER (PARTITION BY al.album_id ORDER BY RANDOM()), al.total_tracks) + 1 as track_number
FROM RAW_ALBUMS al
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 4))
JOIN numbered_songs f ON MOD(al.album_id - 1, 10) + 1 = f.rn
LIMIT 5000;

-- ============================================================================
-- INSERT STREAMING METRICS (50000 records)
-- ============================================================================
INSERT INTO RAW_STREAMING_METRICS
(metric_id, song_id, platform, region, metric_date, stream_count, skip_rate, save_rate, playlist_adds)
WITH numbered_platforms AS (
    SELECT dirty_platform, ROW_NUMBER() OVER (ORDER BY dirty_platform) as rn
    FROM platform_variations
),
numbered_regions AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) as rn
    FROM region_variations
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY s.song_id, RANDOM()) as metric_id,
    s.song_id,
    p.dirty_platform as platform,
    r.dirty_region as region,
    DATEADD('day', -MOD(ROW_NUMBER() OVER (ORDER BY s.song_id, RANDOM()), 90), CURRENT_DATE()) as metric_date,
    FLOOR(RANDOM() * 1000000) as stream_count,
    ROUND(RANDOM() * 0.5, 4) as skip_rate,
    ROUND(RANDOM() * 0.3, 4) as save_rate,
    FLOOR(RANDOM() * 10000) as playlist_adds
FROM RAW_SONGS s
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 10))
JOIN numbered_platforms p ON MOD(s.song_id - 1, 16) + 1 = p.rn
JOIN numbered_regions r ON MOD(s.song_id - 1, 22) + 1 = r.rn
LIMIT 50000;

-- ============================================================================
-- CLEANUP TEMP TABLES
-- ============================================================================
DROP TABLE IF EXISTS artist_pool;
DROP TABLE IF EXISTS foreign_songs;
DROP TABLE IF EXISTS platform_variations;
DROP TABLE IF EXISTS region_variations;

-- Verify data loaded
SELECT 'Data load complete' as status;
SELECT 'RAW_ARTISTS' as table_name, COUNT(*) as row_count FROM RAW_ARTISTS
UNION ALL SELECT 'RAW_ALBUMS', COUNT(*) FROM RAW_ALBUMS
UNION ALL SELECT 'RAW_SONGS', COUNT(*) FROM RAW_SONGS
UNION ALL SELECT 'RAW_STREAMING_METRICS', COUNT(*) FROM RAW_STREAMING_METRICS;

