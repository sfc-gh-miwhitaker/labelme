/*
 * ============================================================================
 * LABELME: AI-POWERED MUSIC DATA QUALITY PIPELINE
 * ============================================================================
 * 
 * DEPLOYMENT INSTRUCTIONS:
 * 1. Open Snowsight (app.snowflake.com)
 * 2. Create a new SQL Worksheet
 * 3. Copy this ENTIRE script and paste into the worksheet
 * 4. Click "Run All" (Ctrl+Shift+Enter)
 * 5. Wait approximately 10 minutes for completion
 * 
 * ============================================================================
 * MACHINE-READABLE METADATA (DO NOT MODIFY)
 * ============================================================================
 * PROJECT_NAME: LABELME
 * AUTHOR: SE Community
 * CREATED: 2025-12-17
 * EXPIRES: 2026-01-16
 * PURPOSE: Music label data model with AI-powered data cleansing pipeline
 * LAST_UPDATED: 2025-12-17
 * GITHUB_REPO: https://github.com/sfc-gh-miwhitaker/labelme
 * ============================================================================
 */

-- ============================================================================
-- STEP 0: EXPIRATION CHECK (HALTS EXECUTION IF EXPIRED)
-- ============================================================================
EXECUTE IMMEDIATE
$$
DECLARE
    v_expiration_date DATE := '2026-01-16';
    demo_expired EXCEPTION (-20001, 'DEMO EXPIRED: This project expired on 2026-01-16. Please contact the SE team for an updated version.');
BEGIN
    IF (CURRENT_DATE() > v_expiration_date) THEN
        RAISE demo_expired;
    END IF;
    RETURN 'Demo is active. Expiration date: ' || v_expiration_date::STRING;
END;
$$;

-- ============================================================================
-- STEP 1: SET CONTEXT
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 2: CREATE WAREHOUSE
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS SFE_LABELME_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

USE WAREHOUSE SFE_LABELME_WH;

-- ============================================================================
-- STEP 3: CREATE DATABASE (if not exists) AND SCHEMAS
-- ============================================================================
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'Shared database for SE demo projects';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS
    COMMENT = 'DEMO: Git repository for LabelMe project | Author: SE Community | Expires: 2026-01-16';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'Shared semantic views for Cortex Analyst agents';

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- STEP 4: CREATE API INTEGRATION FOR GITHUB
-- ============================================================================
CREATE OR REPLACE API INTEGRATION SFE_LABELME_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: GitHub API integration for LabelMe | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 5: CREATE GIT REPOSITORY
-- ============================================================================
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo
    API_INTEGRATION = SFE_LABELME_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/labelme'
    COMMENT = 'DEMO: LabelMe source repository | Author: SE Community | Expires: 2026-01-16';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo FETCH;

-- ============================================================================
-- STEP 6: CREATE RAW TABLES (Dirty Source Data)
-- ============================================================================

-- RAW_ARTISTS: Artist master data with quality issues
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS (
    artist_id INT NOT NULL,
    artist_name VARCHAR(500) NOT NULL COMMENT 'May contain spelling/capitalization errors',
    country_of_origin VARCHAR(100) COMMENT 'Inconsistent formats: USA, United States, US',
    genre_primary VARCHAR(100) COMMENT 'Inconsistent: rock, ROCK, Rock Music',
    genre_secondary VARCHAR(100),
    label_signed_date DATE,
    contract_end_date DATE,
    social_followers INT,
    monthly_listeners INT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_artists PRIMARY KEY (artist_id)
) COMMENT = 'DEMO: Raw artist data with quality issues | Author: SE Community | Expires: 2026-01-16';

-- RAW_ALBUMS: Album catalog with quality issues
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS (
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    album_title VARCHAR(500) NOT NULL COMMENT 'May contain spelling/translation issues',
    release_date DATE,
    album_type VARCHAR(50) COMMENT 'Inconsistent: LP, Album, Full Length',
    genre VARCHAR(100) COMMENT 'Inconsistent formats',
    total_tracks INT,
    label_name VARCHAR(200) COMMENT 'Inconsistent: Universal, UNIVERSAL MUSIC',
    distribution_region VARCHAR(100) COMMENT 'Inconsistent region names',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_albums PRIMARY KEY (album_id),
    CONSTRAINT fk_raw_albums_artist FOREIGN KEY (artist_id) REFERENCES RAW_ARTISTS(artist_id)
) COMMENT = 'DEMO: Raw album data with quality issues | Author: SE Community | Expires: 2026-01-16';

-- RAW_SONGS: Track-level data with quality issues
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS (
    song_id INT NOT NULL,
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    song_title VARCHAR(500) NOT NULL COMMENT 'May need translation/cleaning',
    duration_seconds INT,
    is_explicit BOOLEAN DEFAULT FALSE,
    language_original VARCHAR(50) COMMENT 'Source language code',
    featuring_artists VARCHAR(500) COMMENT 'Inconsistent: feat., ft., featuring',
    isrc_code VARCHAR(20) COMMENT 'International Standard Recording Code',
    track_number INT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_songs PRIMARY KEY (song_id),
    CONSTRAINT fk_raw_songs_album FOREIGN KEY (album_id) REFERENCES RAW_ALBUMS(album_id),
    CONSTRAINT fk_raw_songs_artist FOREIGN KEY (artist_id) REFERENCES RAW_ARTISTS(artist_id)
) COMMENT = 'DEMO: Raw song data with quality issues | Author: SE Community | Expires: 2026-01-16';

-- RAW_STREAMING_METRICS: Platform performance data
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS (
    metric_id INT NOT NULL,
    song_id INT NOT NULL,
    platform VARCHAR(100) NOT NULL COMMENT 'Inconsistent: Spotify, SPOTIFY, spotify',
    region VARCHAR(100) NOT NULL COMMENT 'Inconsistent: US, United States, USA',
    metric_date DATE NOT NULL,
    stream_count INT DEFAULT 0,
    skip_rate DECIMAL(5,4) COMMENT 'Percentage 0.0000 to 1.0000',
    save_rate DECIMAL(5,4) COMMENT 'Percentage 0.0000 to 1.0000',
    playlist_adds INT DEFAULT 0,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_metrics PRIMARY KEY (metric_id),
    CONSTRAINT fk_raw_metrics_song FOREIGN KEY (song_id) REFERENCES RAW_SONGS(song_id)
) COMMENT = 'DEMO: Raw streaming metrics with quality issues | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 7: CREATE STG TABLES (Cleaned Data)
-- ============================================================================

-- STG_ARTISTS: Cleaned artist data
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS (
    artist_id INT NOT NULL,
    artist_name VARCHAR(500) NOT NULL COMMENT 'Cleaned and standardized',
    country_code VARCHAR(10) COMMENT 'ISO country code',
    genre_primary VARCHAR(100) COMMENT 'Standardized genre',
    genre_secondary VARCHAR(100) COMMENT 'Standardized genre',
    label_signed_date DATE,
    contract_end_date DATE,
    social_followers INT,
    monthly_listeners INT,
    quality_score DECIMAL(5,2) COMMENT 'Data quality score 0-100',
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_artists PRIMARY KEY (artist_id)
) COMMENT = 'DEMO: Cleaned artist data | Author: SE Community | Expires: 2026-01-16';

-- STG_ALBUMS: Cleaned album data
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS (
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    album_title VARCHAR(500) NOT NULL COMMENT 'Cleaned title',
    album_title_english VARCHAR(500) COMMENT 'English translation if applicable',
    release_date DATE,
    album_type VARCHAR(50) COMMENT 'Standardized: Single, EP, LP, Compilation',
    genre VARCHAR(100) COMMENT 'Standardized genre',
    total_tracks INT,
    label_name VARCHAR(200) COMMENT 'Standardized label name',
    distribution_region VARCHAR(100) COMMENT 'Standardized region',
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_albums PRIMARY KEY (album_id),
    CONSTRAINT fk_stg_albums_artist FOREIGN KEY (artist_id) REFERENCES STG_ARTISTS(artist_id)
) COMMENT = 'DEMO: Cleaned album data | Author: SE Community | Expires: 2026-01-16';

-- STG_SONGS: Cleaned song data
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS (
    song_id INT NOT NULL,
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    song_title VARCHAR(500) NOT NULL COMMENT 'Cleaned title',
    song_title_english VARCHAR(500) COMMENT 'English translation if applicable',
    duration_seconds INT,
    is_explicit BOOLEAN DEFAULT FALSE,
    language_original VARCHAR(50),
    featuring_artists VARCHAR(500) COMMENT 'Standardized format',
    isrc_code VARCHAR(20),
    track_number INT,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_songs PRIMARY KEY (song_id),
    CONSTRAINT fk_stg_songs_album FOREIGN KEY (album_id) REFERENCES STG_ALBUMS(album_id),
    CONSTRAINT fk_stg_songs_artist FOREIGN KEY (artist_id) REFERENCES STG_ARTISTS(artist_id)
) COMMENT = 'DEMO: Cleaned song data | Author: SE Community | Expires: 2026-01-16';

-- STG_STREAMING_METRICS: Cleaned metrics
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS (
    metric_id INT NOT NULL,
    song_id INT NOT NULL,
    platform VARCHAR(100) NOT NULL COMMENT 'Standardized platform name',
    region_code VARCHAR(10) NOT NULL COMMENT 'ISO country code',
    metric_date DATE NOT NULL,
    stream_count INT DEFAULT 0,
    skip_rate DECIMAL(5,4),
    save_rate DECIMAL(5,4),
    playlist_adds INT DEFAULT 0,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_metrics PRIMARY KEY (metric_id),
    CONSTRAINT fk_stg_metrics_song FOREIGN KEY (song_id) REFERENCES STG_SONGS(song_id)
) COMMENT = 'DEMO: Cleaned streaming metrics | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 8: LOAD SYNTHETIC DIRTY DATA
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

-- Insert artists with dirty data
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS 
(artist_id, artist_name, country_of_origin, genre_primary, genre_secondary, label_signed_date, contract_end_date, social_followers, monthly_listeners)
SELECT 
    ROW_NUMBER() OVER (ORDER BY RANDOM()) as artist_id,
    CASE 
        WHEN RANDOM() < 0.3 THEN p.dirty_name
        WHEN RANDOM() < 0.6 THEN UPPER(p.correct_name)
        ELSE LOWER(p.correct_name)
    END as artist_name,
    CASE 
        WHEN RANDOM() < 0.5 THEN p.country_dirty
        ELSE r.dirty_region
    END as country_of_origin,
    p.genre_dirty as genre_primary,
    CASE WHEN RANDOM() < 0.3 THEN 'electronic' ELSE NULL END as genre_secondary,
    DATEADD('day', -FLOOR(RANDOM() * 3650), CURRENT_DATE()) as label_signed_date,
    DATEADD('day', FLOOR(RANDOM() * 1825), CURRENT_DATE()) as contract_end_date,
    FLOOR(RANDOM() * 50000000) as social_followers,
    FLOOR(RANDOM() * 100000000) as monthly_listeners
FROM TABLE(GENERATOR(ROWCOUNT => 500)) g
CROSS JOIN artist_pool p
CROSS JOIN region_variations r
WHERE MOD(g.SEQ8(), 20) = MOD(p.dirty_name::HASH, 20)
  AND MOD(g.SEQ8(), 22) = MOD(r.dirty_region::HASH, 22)
LIMIT 500;

-- Insert albums
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS
(album_id, artist_id, album_title, release_date, album_type, genre, total_tracks, label_name, distribution_region)
SELECT 
    ROW_NUMBER() OVER (ORDER BY RANDOM()) as album_id,
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
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS a
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 3)) g
CROSS JOIN foreign_songs f
CROSS JOIN region_variations r
WHERE MOD(g.SEQ8(), 10) = MOD(f.title_foreign::HASH, 10)
  AND MOD(a.artist_id, 22) = MOD(r.dirty_region::HASH, 22)
LIMIT 1500;

-- Insert songs
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS
(song_id, album_id, artist_id, song_title, duration_seconds, is_explicit, language_original, featuring_artists, isrc_code, track_number)
SELECT 
    ROW_NUMBER() OVER (ORDER BY RANDOM()) as song_id,
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
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS al
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 4)) g
CROSS JOIN foreign_songs f
WHERE MOD(g.SEQ8(), 10) = MOD(f.title_foreign::HASH, 10)
LIMIT 5000;

-- Insert streaming metrics
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS
(metric_id, song_id, platform, region, metric_date, stream_count, skip_rate, save_rate, playlist_adds)
SELECT 
    ROW_NUMBER() OVER (ORDER BY RANDOM()) as metric_id,
    s.song_id,
    p.dirty_platform as platform,
    r.dirty_region as region,
    DATEADD('day', -MOD(ROW_NUMBER() OVER (ORDER BY RANDOM()), 90), CURRENT_DATE()) as metric_date,
    FLOOR(RANDOM() * 1000000) as stream_count,
    ROUND(RANDOM() * 0.5, 4) as skip_rate,
    ROUND(RANDOM() * 0.3, 4) as save_rate,
    FLOOR(RANDOM() * 10000) as playlist_adds
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS s
CROSS JOIN platform_variations p
CROSS JOIN region_variations r
WHERE MOD(s.song_id, 16) = MOD(p.dirty_platform::HASH, 16)
  AND MOD(s.song_id, 22) = MOD(r.dirty_region::HASH, 22)
LIMIT 50000;

-- Clean up temp tables
DROP TABLE IF EXISTS artist_pool;
DROP TABLE IF EXISTS foreign_songs;
DROP TABLE IF EXISTS platform_variations;
DROP TABLE IF EXISTS region_variations;

-- ============================================================================
-- STEP 9: CREATE STREAMS FOR CDC
-- ============================================================================

CREATE OR REPLACE STREAM SNOWFLAKE_EXAMPLE.LABELME.ARTISTS_STREAM 
    ON TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS
    COMMENT = 'DEMO: CDC stream for artists | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM SNOWFLAKE_EXAMPLE.LABELME.ALBUMS_STREAM 
    ON TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS
    COMMENT = 'DEMO: CDC stream for albums | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM SNOWFLAKE_EXAMPLE.LABELME.SONGS_STREAM 
    ON TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS
    COMMENT = 'DEMO: CDC stream for songs | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM SNOWFLAKE_EXAMPLE.LABELME.METRICS_STREAM 
    ON TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS
    COMMENT = 'DEMO: CDC stream for metrics | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 10: CREATE CORTEX AI CLEANING PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_WITH_CORTEX()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'DEMO: AI-powered data cleaning procedure | Author: SE Community | Expires: 2026-01-16'
AS
$$
BEGIN
    -- Clean artists: Fix spelling, capitalization, standardize countries
    MERGE INTO SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS t
    USING (
        SELECT 
            artist_id,
            -- Use Cortex to clean artist names (simplified for demo)
            TRIM(SNOWFLAKE.CORTEX.COMPLETE(
                'mistral-7b',
                'Fix the spelling and capitalization of this music artist name. Return ONLY the corrected name, nothing else: ' || artist_name
            )) as artist_name_clean,
            -- Standardize country codes
            CASE 
                WHEN UPPER(country_of_origin) IN ('USA', 'UNITED STATES', 'UNITED STATES OF AMERICA', 'U.S.A.') THEN 'US'
                WHEN UPPER(country_of_origin) IN ('UK', 'UNITED KINGDOM', 'U.K.', 'GREAT BRITAIN') THEN 'GB'
                WHEN UPPER(country_of_origin) IN ('CANADA') THEN 'CA'
                WHEN UPPER(country_of_origin) IN ('GERMANY', 'DEUTSCHLAND') THEN 'DE'
                WHEN UPPER(country_of_origin) IN ('FRANCE') THEN 'FR'
                WHEN UPPER(country_of_origin) IN ('JAPAN') THEN 'JP'
                WHEN UPPER(country_of_origin) IN ('AUSTRALIA') THEN 'AU'
                WHEN UPPER(country_of_origin) IN ('BRAZIL', 'BRASIL') THEN 'BR'
                WHEN UPPER(country_of_origin) IN ('MEXICO') THEN 'MX'
                WHEN UPPER(country_of_origin) IN ('SPAIN', 'ESPANA') THEN 'ES'
                WHEN UPPER(country_of_origin) IN ('SOUTH KOREA', 'KOREA') THEN 'KR'
                WHEN UPPER(country_of_origin) IN ('PUERTO RICO') THEN 'PR'
                WHEN UPPER(country_of_origin) IN ('COLOMBIA') THEN 'CO'
                WHEN UPPER(country_of_origin) IN ('BARBADOS') THEN 'BB'
                ELSE UPPER(LEFT(country_of_origin, 2))
            END as country_code,
            -- Standardize genres
            INITCAP(TRIM(REPLACE(REPLACE(genre_primary, 'music', ''), '/', ' '))) as genre_primary_clean,
            INITCAP(TRIM(genre_secondary)) as genre_secondary_clean,
            label_signed_date,
            contract_end_date,
            social_followers,
            monthly_listeners,
            -- Calculate quality score based on how much cleaning was needed
            CASE 
                WHEN artist_name = INITCAP(artist_name) THEN 90
                ELSE 70
            END + 
            CASE 
                WHEN country_of_origin IN ('US', 'GB', 'CA', 'DE', 'FR') THEN 10
                ELSE 0
            END as quality_score
        FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS
        LIMIT 100  -- Process in batches for demo
    ) s
    ON t.artist_id = s.artist_id
    WHEN MATCHED THEN UPDATE SET
        artist_name = s.artist_name_clean,
        country_code = s.country_code,
        genre_primary = s.genre_primary_clean,
        genre_secondary = s.genre_secondary_clean,
        label_signed_date = s.label_signed_date,
        contract_end_date = s.contract_end_date,
        social_followers = s.social_followers,
        monthly_listeners = s.monthly_listeners,
        quality_score = s.quality_score,
        processed_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT (
        artist_id, artist_name, country_code, genre_primary, genre_secondary,
        label_signed_date, contract_end_date, social_followers, monthly_listeners, quality_score
    ) VALUES (
        s.artist_id, s.artist_name_clean, s.country_code, s.genre_primary_clean, s.genre_secondary_clean,
        s.label_signed_date, s.contract_end_date, s.social_followers, s.monthly_listeners, s.quality_score
    );

    RETURN 'Data cleaning completed successfully';
END;
$$;

-- ============================================================================
-- STEP 11: INITIAL DATA CLEANING (Run Cortex on sample)
-- ============================================================================

-- For demo, do a simple initial load with basic cleaning (Cortex calls can be expensive at scale)
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS
(artist_id, artist_name, country_code, genre_primary, genre_secondary, label_signed_date, contract_end_date, social_followers, monthly_listeners, quality_score)
SELECT 
    artist_id,
    INITCAP(TRIM(artist_name)) as artist_name,
    CASE 
        WHEN UPPER(country_of_origin) IN ('USA', 'UNITED STATES', 'UNITED STATES OF AMERICA', 'U.S.A.') THEN 'US'
        WHEN UPPER(country_of_origin) IN ('UK', 'UNITED KINGDOM', 'U.K.', 'GREAT BRITAIN') THEN 'GB'
        WHEN UPPER(country_of_origin) IN ('CANADA') THEN 'CA'
        WHEN UPPER(country_of_origin) IN ('GERMANY', 'DEUTSCHLAND') THEN 'DE'
        WHEN UPPER(country_of_origin) IN ('FRANCE') THEN 'FR'
        WHEN UPPER(country_of_origin) IN ('JAPAN') THEN 'JP'
        WHEN UPPER(country_of_origin) IN ('SOUTH KOREA', 'KOREA') THEN 'KR'
        WHEN UPPER(country_of_origin) IN ('PUERTO RICO') THEN 'PR'
        WHEN UPPER(country_of_origin) IN ('COLOMBIA') THEN 'CO'
        WHEN UPPER(country_of_origin) IN ('BARBADOS') THEN 'BB'
        ELSE UPPER(LEFT(country_of_origin, 2))
    END as country_code,
    INITCAP(TRIM(REPLACE(genre_primary, 'music', ''))) as genre_primary,
    INITCAP(TRIM(genre_secondary)) as genre_secondary,
    label_signed_date,
    contract_end_date,
    social_followers,
    monthly_listeners,
    ROUND(RANDOM() * 30 + 70, 2) as quality_score
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS;

INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS
(album_id, artist_id, album_title, album_title_english, release_date, album_type, genre, total_tracks, label_name, distribution_region)
SELECT 
    album_id,
    artist_id,
    INITCAP(TRIM(album_title)) as album_title,
    CASE 
        WHEN album_title NOT REGEXP '^[a-zA-Z0-9 ]+$' 
        THEN INITCAP(TRIM(album_title)) -- Would use CORTEX.TRANSLATE in production
        ELSE NULL 
    END as album_title_english,
    release_date,
    CASE 
        WHEN UPPER(album_type) IN ('LP', 'ALBUM', 'FULL LENGTH') THEN 'LP'
        WHEN UPPER(album_type) = 'EP' THEN 'EP'
        WHEN UPPER(album_type) = 'SINGLE' THEN 'Single'
        ELSE 'LP'
    END as album_type,
    INITCAP(TRIM(genre)) as genre,
    total_tracks,
    CASE 
        WHEN UPPER(label_name) LIKE '%UNIVERSAL%' THEN 'Universal Music Group'
        WHEN UPPER(label_name) LIKE '%SONY%' THEN 'Sony Music Entertainment'
        WHEN UPPER(label_name) LIKE '%WARNER%' THEN 'Warner Music Group'
        ELSE INITCAP(label_name)
    END as label_name,
    distribution_region
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS;

INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS
(song_id, album_id, artist_id, song_title, song_title_english, duration_seconds, is_explicit, language_original, featuring_artists, isrc_code, track_number)
SELECT 
    song_id,
    album_id,
    artist_id,
    INITCAP(TRIM(song_title)) as song_title,
    CASE 
        WHEN language_original != 'en' THEN INITCAP(TRIM(song_title)) -- Would use CORTEX.TRANSLATE
        ELSE NULL 
    END as song_title_english,
    duration_seconds,
    is_explicit,
    language_original,
    CASE 
        WHEN featuring_artists IS NOT NULL THEN REGEXP_REPLACE(featuring_artists, '(feat\\.|ft\\.|featuring)', 'feat.')
        ELSE NULL
    END as featuring_artists,
    isrc_code,
    track_number
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS;

INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS
(metric_id, song_id, platform, region_code, metric_date, stream_count, skip_rate, save_rate, playlist_adds)
SELECT 
    metric_id,
    song_id,
    CASE 
        WHEN UPPER(platform) LIKE '%SPOTIFY%' THEN 'Spotify'
        WHEN UPPER(platform) LIKE '%APPLE%' THEN 'Apple Music'
        WHEN UPPER(platform) LIKE '%AMAZON%' THEN 'Amazon Music'
        WHEN UPPER(platform) LIKE '%YOUTUBE%' THEN 'YouTube Music'
        WHEN UPPER(platform) LIKE '%TIDAL%' THEN 'Tidal'
        WHEN UPPER(platform) LIKE '%DEEZER%' THEN 'Deezer'
        WHEN UPPER(platform) LIKE '%PANDORA%' THEN 'Pandora'
        ELSE INITCAP(platform)
    END as platform,
    CASE 
        WHEN UPPER(region) IN ('USA', 'UNITED STATES', 'UNITED STATES OF AMERICA', 'U.S.A.') THEN 'US'
        WHEN UPPER(region) IN ('UK', 'UNITED KINGDOM', 'U.K.', 'GREAT BRITAIN') THEN 'GB'
        WHEN UPPER(region) IN ('CANADA') THEN 'CA'
        WHEN UPPER(region) IN ('GERMANY', 'DEUTSCHLAND') THEN 'DE'
        WHEN UPPER(region) IN ('FRANCE') THEN 'FR'
        WHEN UPPER(region) IN ('JAPAN') THEN 'JP'
        WHEN UPPER(region) IN ('AUSTRALIA') THEN 'AU'
        WHEN UPPER(region) IN ('BRAZIL', 'BRASIL') THEN 'BR'
        WHEN UPPER(region) IN ('MEXICO') THEN 'MX'
        WHEN UPPER(region) IN ('SPAIN', 'ESPANA') THEN 'ES'
        ELSE UPPER(LEFT(region, 2))
    END as region_code,
    metric_date,
    stream_count,
    skip_rate,
    save_rate,
    playlist_adds
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS;

-- ============================================================================
-- STEP 12: CREATE ANALYTICS VIEWS
-- ============================================================================

-- Artist Performance View
CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.LABELME.V_ARTIST_PERFORMANCE
COMMENT = 'DEMO: Artist performance metrics | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    a.artist_id,
    a.artist_name,
    a.country_code,
    a.genre_primary,
    a.monthly_listeners,
    a.social_followers,
    a.contract_end_date,
    CASE 
        WHEN a.contract_end_date < CURRENT_DATE() THEN 'Expired'
        WHEN a.contract_end_date < DATEADD('day', 30, CURRENT_DATE()) THEN 'Expiring Soon'
        WHEN a.contract_end_date < DATEADD('day', 90, CURRENT_DATE()) THEN 'Renewal Upcoming'
        ELSE 'Active'
    END as contract_status,
    COUNT(DISTINCT al.album_id) as album_count,
    COUNT(DISTINCT s.song_id) as song_count,
    SUM(m.stream_count) as total_streams,
    AVG(m.skip_rate) as avg_skip_rate,
    AVG(m.save_rate) as avg_save_rate,
    a.quality_score
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS a
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS al ON a.artist_id = al.artist_id
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS s ON a.artist_id = s.artist_id
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS m ON s.song_id = m.song_id
GROUP BY 1,2,3,4,5,6,7,8,13;

-- Catalog Health View
CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.LABELME.V_CATALOG_HEALTH
COMMENT = 'DEMO: Catalog health metrics | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    COUNT(DISTINCT s.song_id) as total_songs,
    COUNT(DISTINCT al.album_id) as total_albums,
    COUNT(DISTINCT a.artist_id) as total_artists,
    COUNT(CASE WHEN s.is_explicit THEN 1 END) as explicit_songs,
    ROUND(COUNT(CASE WHEN s.is_explicit THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as explicit_percentage,
    COUNT(DISTINCT s.language_original) as language_count,
    COUNT(CASE WHEN s.language_original != 'en' THEN 1 END) as non_english_songs,
    COUNT(CASE WHEN s.song_title_english IS NOT NULL THEN 1 END) as translated_songs,
    AVG(s.duration_seconds) as avg_duration_seconds,
    COUNT(CASE WHEN s.featuring_artists IS NOT NULL THEN 1 END) as collaboration_songs
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS s
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS al ON s.album_id = al.album_id
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS a ON s.artist_id = a.artist_id;

-- Streaming Trends View
CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.LABELME.V_STREAMING_TRENDS
COMMENT = 'DEMO: Streaming trends by platform and region | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    metric_date,
    platform,
    region_code,
    COUNT(DISTINCT song_id) as songs_streamed,
    SUM(stream_count) as total_streams,
    AVG(skip_rate) as avg_skip_rate,
    AVG(save_rate) as avg_save_rate,
    SUM(playlist_adds) as total_playlist_adds
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS
GROUP BY 1,2,3;

-- Data Quality Scorecard View
CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.LABELME.V_DATA_QUALITY_SCORECARD
COMMENT = 'DEMO: Data quality metrics summary | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    'Artists' as entity,
    COUNT(*) as total_records,
    AVG(quality_score) as avg_quality_score,
    COUNT(CASE WHEN quality_score >= 90 THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN quality_score >= 90 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN country_code IS NOT NULL THEN 1 END) as standardized_country_count,
    CURRENT_TIMESTAMP() as measured_at
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS
UNION ALL
SELECT 
    'Songs' as entity,
    COUNT(*) as total_records,
    NULL as avg_quality_score,
    COUNT(CASE WHEN song_title = INITCAP(song_title) THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN song_title = INITCAP(song_title) THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN featuring_artists LIKE 'feat.%' OR featuring_artists IS NULL THEN 1 END) as standardized_count,
    CURRENT_TIMESTAMP() as measured_at
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS
UNION ALL
SELECT 
    'Streaming Metrics' as entity,
    COUNT(*) as total_records,
    NULL as avg_quality_score,
    COUNT(CASE WHEN platform IN ('Spotify', 'Apple Music', 'Amazon Music', 'YouTube Music', 'Tidal', 'Deezer', 'Pandora') THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN platform IN ('Spotify', 'Apple Music', 'Amazon Music', 'YouTube Music', 'Tidal', 'Deezer', 'Pandora') THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN LENGTH(region_code) = 2 THEN 1 END) as standardized_count,
    CURRENT_TIMESTAMP() as measured_at
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS;

-- ============================================================================
-- STEP 13: CREATE DAILY CLEANING TASK
-- ============================================================================

CREATE OR REPLACE TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK
    WAREHOUSE = SFE_LABELME_WH
    SCHEDULE = 'USING CRON 0 2 * * * America/Los_Angeles'  -- Daily at 2 AM PT
    COMMENT = 'DEMO: Daily data cleaning task | Author: SE Community | Expires: 2026-01-16'
AS
    CALL SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_WITH_CORTEX();

-- Note: Task is created in suspended state. Resume with:
-- ALTER TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK RESUME;

-- ============================================================================
-- STEP 14: CREATE STREAMLIT DASHBOARD
-- ============================================================================

CREATE OR REPLACE STREAMLIT SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_LABELME_WH
    COMMENT = 'DEMO: LabelMe Data Quality Dashboard | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 15: GRANT PERMISSIONS
-- ============================================================================

-- Grant usage on warehouse to public for demo accessibility
GRANT USAGE ON WAREHOUSE SFE_LABELME_WH TO ROLE PUBLIC;

-- Grant access to the database and schemas
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;

-- Grant Streamlit access
GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD TO ROLE PUBLIC;

-- ============================================================================
-- STEP 16: VERIFICATION
-- ============================================================================

-- Show created objects
SELECT 'Tables Created' as status, COUNT(*) as count 
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES 
WHERE table_schema = 'LABELME' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'Views Created', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.VIEWS 
WHERE table_schema = 'LABELME'
UNION ALL
SELECT 'Streams Created', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES 
WHERE table_schema = 'LABELME' AND table_type = 'STREAM';

-- Show record counts
SELECT 'RAW_ARTISTS' as table_name, COUNT(*) as row_count FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS
UNION ALL SELECT 'RAW_ALBUMS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS
UNION ALL SELECT 'RAW_SONGS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS
UNION ALL SELECT 'RAW_STREAMING_METRICS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS
UNION ALL SELECT 'STG_ARTISTS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS
UNION ALL SELECT 'STG_ALBUMS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS
UNION ALL SELECT 'STG_SONGS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS
UNION ALL SELECT 'STG_STREAMING_METRICS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS;

-- Show data quality scorecard
SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.V_DATA_QUALITY_SCORECARD;

-- ============================================================================
-- DEPLOYMENT COMPLETE!
-- ============================================================================
-- 
-- Next Steps:
-- 1. Open Streamlit from the Snowsight sidebar
-- 2. Click on LABELME_DASHBOARD to view the data quality dashboard
-- 3. Explore the data using the views created
-- 4. To enable the daily task: ALTER TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK RESUME;
-- 
-- For cleanup, run: sql/99_cleanup/teardown_all.sql
-- 
-- ============================================================================

