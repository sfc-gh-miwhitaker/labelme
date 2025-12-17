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
-- Uses simple cross join with modulo to distribute data
-- ============================================================================
INSERT INTO RAW_ARTISTS 
(artist_id, artist_name, country_of_origin, genre_primary, genre_secondary, label_signed_date, contract_end_date, social_followers, monthly_listeners)
WITH artist_numbered AS (
    SELECT dirty_name, correct_name, country_dirty, genre_dirty,
           ROW_NUMBER() OVER (ORDER BY dirty_name) - 1 as idx
    FROM artist_pool
),
region_numbered AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) - 1 as idx
    FROM region_variations
),
row_nums AS (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT 
    r.rn as artist_id,
    CASE MOD(r.rn, 3)
        WHEN 0 THEN a.dirty_name
        WHEN 1 THEN UPPER(a.correct_name)
        ELSE LOWER(a.correct_name)
    END as artist_name,
    CASE MOD(r.rn, 2)
        WHEN 0 THEN a.country_dirty
        ELSE reg.dirty_region
    END as country_of_origin,
    a.genre_dirty as genre_primary,
    CASE WHEN MOD(r.rn, 3) = 0 THEN 'electronic' ELSE NULL END as genre_secondary,
    DATEADD('day', -MOD(r.rn * 7, 3650), CURRENT_DATE()) as label_signed_date,
    DATEADD('day', MOD(r.rn * 3, 1825), CURRENT_DATE()) as contract_end_date,
    MOD(r.rn * 100000, 50000000) as social_followers,
    MOD(r.rn * 200000, 100000000) as monthly_listeners
FROM row_nums r
JOIN artist_numbered a ON MOD(r.rn - 1, 20) = a.idx
JOIN region_numbered reg ON MOD(r.rn - 1, 22) = reg.idx;

-- ============================================================================
-- INSERT ALBUMS (1500 records)
-- ============================================================================
INSERT INTO RAW_ALBUMS
(album_id, artist_id, album_title, release_date, album_type, genre, total_tracks, label_name, distribution_region)
WITH song_numbered AS (
    SELECT title_foreign, ROW_NUMBER() OVER (ORDER BY title_foreign) - 1 as idx
    FROM foreign_songs
),
region_numbered AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) - 1 as idx
    FROM region_variations
),
artist_data AS (
    SELECT artist_id, genre_primary, ROW_NUMBER() OVER (ORDER BY artist_id) as artist_rn
    FROM RAW_ARTISTS
),
row_nums AS (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 1500))
)
SELECT 
    r.rn as album_id,
    a.artist_id,
    CASE MOD(r.rn, 5)
        WHEN 0 THEN f.title_foreign
        WHEN 1 THEN UPPER('Album ' || r.rn::VARCHAR)
        WHEN 2 THEN 'album ' || r.rn::VARCHAR
        ELSE 'Album Title ' || r.rn::VARCHAR
    END as album_title,
    DATEADD('day', -MOD(r.rn * 2, 3650), CURRENT_DATE()) as release_date,
    CASE MOD(r.rn, 4)
        WHEN 0 THEN 'LP'
        WHEN 1 THEN 'Album'
        WHEN 2 THEN 'Full Length'
        ELSE 'EP'
    END as album_type,
    a.genre_primary as genre,
    MOD(r.rn, 15) + 5 as total_tracks,
    CASE MOD(r.rn, 5)
        WHEN 0 THEN 'Universal'
        WHEN 1 THEN 'UNIVERSAL MUSIC'
        WHEN 2 THEN 'Sony Music'
        WHEN 3 THEN 'SONY'
        ELSE 'Warner Music Group'
    END as label_name,
    reg.dirty_region as distribution_region
FROM row_nums r
JOIN artist_data a ON MOD(r.rn - 1, 500) + 1 = a.artist_rn
JOIN song_numbered f ON MOD(r.rn - 1, 10) = f.idx
JOIN region_numbered reg ON MOD(r.rn - 1, 22) = reg.idx;

-- ============================================================================
-- INSERT SONGS (5000 records)
-- ============================================================================
INSERT INTO RAW_SONGS
(song_id, album_id, artist_id, song_title, duration_seconds, is_explicit, language_original, featuring_artists, isrc_code, track_number)
WITH song_numbered AS (
    SELECT title_foreign, language_code, ROW_NUMBER() OVER (ORDER BY title_foreign) - 1 as idx
    FROM foreign_songs
),
album_data AS (
    SELECT album_id, artist_id, total_tracks, ROW_NUMBER() OVER (ORDER BY album_id) as album_rn
    FROM RAW_ALBUMS
),
row_nums AS (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
)
SELECT 
    r.rn as song_id,
    al.album_id,
    al.artist_id,
    CASE MOD(r.rn, 7)
        WHEN 0 THEN f.title_foreign
        WHEN 1 THEN UPPER('Track ' || r.rn::VARCHAR)
        WHEN 2 THEN 'track ' || r.rn::VARCHAR
        ELSE 'Song Title ' || r.rn::VARCHAR
    END as song_title,
    MOD(r.rn * 3, 180) + 120 as duration_seconds,
    MOD(r.rn, 7) = 0 as is_explicit,
    CASE WHEN MOD(r.rn, 7) = 0 THEN f.language_code ELSE 'en' END as language_original,
    CASE MOD(r.rn, 4)
        WHEN 0 THEN NULL
        WHEN 1 THEN 'feat. Artist ' || MOD(r.rn, 100)::VARCHAR
        WHEN 2 THEN 'ft. Artist ' || MOD(r.rn, 100)::VARCHAR
        ELSE 'featuring Artist ' || MOD(r.rn, 100)::VARCHAR
    END as featuring_artists,
    'US' || LPAD(MOD(r.rn * 12345, 1000000000)::VARCHAR, 9, '0') as isrc_code,
    MOD(r.rn - 1, al.total_tracks) + 1 as track_number
FROM row_nums r
JOIN album_data al ON MOD(r.rn - 1, 1500) + 1 = al.album_rn
JOIN song_numbered f ON MOD(r.rn - 1, 10) = f.idx;

-- ============================================================================
-- INSERT STREAMING METRICS (50000 records)
-- ============================================================================
INSERT INTO RAW_STREAMING_METRICS
(metric_id, song_id, platform, region, metric_date, stream_count, skip_rate, save_rate, playlist_adds)
WITH platform_numbered AS (
    SELECT dirty_platform, ROW_NUMBER() OVER (ORDER BY dirty_platform) - 1 as idx
    FROM platform_variations
),
region_numbered AS (
    SELECT dirty_region, ROW_NUMBER() OVER (ORDER BY dirty_region) - 1 as idx
    FROM region_variations
),
song_data AS (
    SELECT song_id, ROW_NUMBER() OVER (ORDER BY song_id) as song_rn
    FROM RAW_SONGS
),
row_nums AS (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
)
SELECT 
    r.rn as metric_id,
    s.song_id,
    p.dirty_platform as platform,
    reg.dirty_region as region,
    DATEADD('day', -MOD(r.rn, 90), CURRENT_DATE()) as metric_date,
    MOD(r.rn * 20, 1000000) as stream_count,
    ROUND(MOD(r.rn * 7, 50) / 100.0, 4) as skip_rate,
    ROUND(MOD(r.rn * 3, 30) / 100.0, 4) as save_rate,
    MOD(r.rn * 2, 10000) as playlist_adds
FROM row_nums r
JOIN song_data s ON MOD(r.rn - 1, 5000) + 1 = s.song_rn
JOIN platform_numbered p ON MOD(r.rn - 1, 16) = p.idx
JOIN region_numbered reg ON MOD(r.rn - 1, 22) = reg.idx;

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
