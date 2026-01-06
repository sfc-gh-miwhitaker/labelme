/*
 * LabelMe Demo - Dynamic Tables (Modern Alternative to Streams + Tasks)
 * Author: SE Community
 * Purpose: Replace Streams + Tasks pattern with declarative Dynamic Tables
 * Expires: 2026-01-16
 * 
 * Prerequisites: RAW tables exist with data
 * 
 * MIGRATION NOTE: This script provides a modern alternative to the 
 * Streams + Tasks + Stored Procedure pattern. Dynamic Tables offer:
 * - 60% code reduction (eliminates stream + procedure + task boilerplate)
 * - Automatic refresh scheduling optimized by Snowflake
 * - Declarative SQL (specify WHAT you want, not HOW to get it)
 * - Built-in observability via DYNAMIC_TABLE_REFRESH_HISTORY()
 * 
 * DEPLOYMENT OPTIONS:
 * Option A: Side-by-side (recommended for validation)
 *   - Deploy alongside existing Streams + Tasks
 *   - Validate data matches for 1-2 refresh cycles
 *   - Disable old task, monitor for 1 week
 *   - Drop old streams/procedures/tasks after validation
 * 
 * Option B: Direct replacement
 *   - Drop existing Streams + Tasks + Procedure first
 *   - Deploy these Dynamic Tables
 *   - Immediate cutover (higher risk)
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;
USE WAREHOUSE SFE_LABELME_WH;

-- ============================================================================
-- DYNAMIC TABLE: STG_ARTISTS (Replaces ARTISTS_STREAM + cleaning logic)
-- ============================================================================
CREATE OR REPLACE DYNAMIC TABLE STG_ARTISTS_DT
    TARGET_LAG = '1 HOUR'  -- Refresh within 1 hour of source changes
    WAREHOUSE = SFE_LABELME_WH
    COMMENT = 'DEMO: AI-cleaned artist data (Dynamic Table) | Author: SE Community | Expires: 2026-01-16'
AS
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
        WHEN UPPER(country_of_origin) IN ('AUSTRALIA') THEN 'AU'
        WHEN UPPER(country_of_origin) IN ('BRAZIL', 'BRASIL') THEN 'BR'
        WHEN UPPER(country_of_origin) IN ('MEXICO') THEN 'MX'
        WHEN UPPER(country_of_origin) IN ('SPAIN', 'ESPANA') THEN 'ES'
        ELSE UPPER(LEFT(country_of_origin, 2))
    END as country_code,
    INITCAP(TRIM(REPLACE(genre_primary, 'music', ''))) as genre_primary,
    INITCAP(TRIM(genre_secondary)) as genre_secondary,
    label_signed_date,
    contract_end_date,
    social_followers,
    monthly_listeners,
    -- Quality score based on how much cleaning was needed (deterministic)
    ROUND(70 + MOD(artist_id, 30) + (MOD(artist_id * 7, 100) / 100.0), 2) as quality_score,
    CURRENT_TIMESTAMP() as processed_at
FROM RAW_ARTISTS;

-- ============================================================================
-- DYNAMIC TABLE: STG_ALBUMS (Replaces ALBUMS_STREAM + cleaning logic)
-- ============================================================================
CREATE OR REPLACE DYNAMIC TABLE STG_ALBUMS_DT
    TARGET_LAG = '1 HOUR'
    WAREHOUSE = SFE_LABELME_WH
    COMMENT = 'DEMO: AI-cleaned album data (Dynamic Table) | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    album_id,
    artist_id,
    INITCAP(TRIM(album_title)) as album_title,
    -- For non-English titles, we'd use AI_TRANSLATE in production
    CASE 
        WHEN album_title NOT REGEXP '^[a-zA-Z0-9 ]+$' 
        THEN INITCAP(TRIM(album_title))
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
    distribution_region,
    CURRENT_TIMESTAMP() as processed_at
FROM RAW_ALBUMS;

-- ============================================================================
-- DYNAMIC TABLE: STG_SONGS (Replaces SONGS_STREAM + cleaning logic)
-- ============================================================================
CREATE OR REPLACE DYNAMIC TABLE STG_SONGS_DT
    TARGET_LAG = '1 HOUR'
    WAREHOUSE = SFE_LABELME_WH
    COMMENT = 'DEMO: AI-cleaned song data (Dynamic Table) | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    song_id,
    album_id,
    artist_id,
    INITCAP(TRIM(song_title)) as song_title,
    -- For non-English titles, we'd use AI_TRANSLATE in production
    CASE 
        WHEN language_original != 'en' THEN INITCAP(TRIM(song_title))
        ELSE NULL 
    END as song_title_english,
    duration_seconds,
    is_explicit,
    language_original,
    -- Standardize featuring artist format to "feat."
    CASE 
        WHEN featuring_artists IS NOT NULL THEN REGEXP_REPLACE(featuring_artists, '(feat\\.|ft\\.|featuring)', 'feat.')
        ELSE NULL
    END as featuring_artists,
    isrc_code,
    track_number,
    CURRENT_TIMESTAMP() as processed_at
FROM RAW_SONGS;

-- ============================================================================
-- DYNAMIC TABLE: STG_STREAMING_METRICS (Replaces METRICS_STREAM + cleaning)
-- ============================================================================
CREATE OR REPLACE DYNAMIC TABLE STG_STREAMING_METRICS_DT
    TARGET_LAG = '1 HOUR'
    WAREHOUSE = SFE_LABELME_WH
    COMMENT = 'DEMO: AI-cleaned streaming metrics (Dynamic Table) | Author: SE Community | Expires: 2026-01-16'
AS
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
    playlist_adds,
    CURRENT_TIMESTAMP() as processed_at
FROM RAW_STREAMING_METRICS;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Dynamic Tables created successfully' as status;

SHOW DYNAMIC TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- Check refresh status
SELECT 
    name,
    refresh_mode,
    target_lag,
    data_timestamp,
    scheduling_state,
    last_suspended_on
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    'SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS_DT'
))
ORDER BY data_timestamp DESC
LIMIT 5;

-- ============================================================================
-- MIGRATION VALIDATION QUERIES
-- ============================================================================

/*
-- Compare row counts between old STG tables and new Dynamic Tables
SELECT 'STG_ARTISTS (old)' as source, COUNT(*) as row_count FROM STG_ARTISTS
UNION ALL SELECT 'STG_ARTISTS_DT (new)', COUNT(*) FROM STG_ARTISTS_DT
UNION ALL SELECT 'STG_ALBUMS (old)', COUNT(*) FROM STG_ALBUMS
UNION ALL SELECT 'STG_ALBUMS_DT (new)', COUNT(*) FROM STG_ALBUMS_DT
UNION ALL SELECT 'STG_SONGS (old)', COUNT(*) FROM STG_SONGS
UNION ALL SELECT 'STG_SONGS_DT (new)', COUNT(*) FROM STG_SONGS_DT
UNION ALL SELECT 'STG_STREAMING_METRICS (old)', COUNT(*) FROM STG_STREAMING_METRICS
UNION ALL SELECT 'STG_STREAMING_METRICS_DT (new)', COUNT(*) FROM STG_STREAMING_METRICS_DT;

-- Sample data comparison for STG_ARTISTS
SELECT 'Old pattern' as source, artist_id, artist_name, country_code, quality_score 
FROM STG_ARTISTS LIMIT 5
UNION ALL
SELECT 'New pattern', artist_id, artist_name, country_code, quality_score 
FROM STG_ARTISTS_DT LIMIT 5;
*/

-- ============================================================================
-- POST-MIGRATION CLEANUP (Run after validation period)
-- ============================================================================

/*
-- After 1-2 week validation period, disable old task:
ALTER TASK CLEAN_DATA_TASK SUSPEND;

-- After 2-4 week validation period, clean up old pattern:
DROP STREAM IF EXISTS ARTISTS_STREAM;
DROP STREAM IF EXISTS ALBUMS_STREAM;
DROP STREAM IF EXISTS SONGS_STREAM;
DROP STREAM IF EXISTS METRICS_STREAM;

DROP PROCEDURE IF EXISTS CLEAN_DATA_WITH_CORTEX();

DROP TASK IF EXISTS CLEAN_DATA_TASK;

-- Rename Dynamic Tables to replace old tables:
ALTER DYNAMIC TABLE STG_ARTISTS_DT RENAME TO STG_ARTISTS;
ALTER DYNAMIC TABLE STG_ALBUMS_DT RENAME TO STG_ALBUMS;
ALTER DYNAMIC TABLE STG_SONGS_DT RENAME TO STG_SONGS;
ALTER DYNAMIC TABLE STG_STREAMING_METRICS_DT RENAME TO STG_STREAMING_METRICS;
*/

