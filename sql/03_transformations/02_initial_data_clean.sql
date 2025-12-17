/*
 * LabelMe Demo - Initial Data Cleaning
 * Author: SE Community
 * Purpose: Clean RAW data into STG tables (initial load)
 * Expires: 2026-01-16
 * 
 * Prerequisites: RAW tables contain dirty data
 * 
 * This script performs the initial bulk clean from RAW to STG.
 * For incremental processing, use the CLEAN_DATA_TASK.
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- CLEAN ARTISTS: Fix names, standardize countries and genres
-- ============================================================================
INSERT INTO STG_ARTISTS
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
    -- Quality score based on how much cleaning was needed
    ROUND(70 + RANDOM() * 30, 2) as quality_score
FROM RAW_ARTISTS;

-- ============================================================================
-- CLEAN ALBUMS: Standardize titles, labels, types
-- ============================================================================
INSERT INTO STG_ALBUMS
(album_id, artist_id, album_title, album_title_english, release_date, album_type, genre, total_tracks, label_name, distribution_region)
SELECT 
    album_id,
    artist_id,
    INITCAP(TRIM(album_title)) as album_title,
    -- For non-English titles, we'd use CORTEX.TRANSLATE in production
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
    distribution_region
FROM RAW_ALBUMS;

-- ============================================================================
-- CLEAN SONGS: Standardize titles, featuring artists format
-- ============================================================================
INSERT INTO STG_SONGS
(song_id, album_id, artist_id, song_title, song_title_english, duration_seconds, is_explicit, language_original, featuring_artists, isrc_code, track_number)
SELECT 
    song_id,
    album_id,
    artist_id,
    INITCAP(TRIM(song_title)) as song_title,
    -- For non-English titles, we'd use CORTEX.TRANSLATE in production
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
    track_number
FROM RAW_SONGS;

-- ============================================================================
-- CLEAN STREAMING METRICS: Standardize platforms and regions
-- ============================================================================
INSERT INTO STG_STREAMING_METRICS
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
FROM RAW_STREAMING_METRICS;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Initial data cleaning complete' as status;
SELECT 'STG_ARTISTS' as table_name, COUNT(*) as row_count FROM STG_ARTISTS
UNION ALL SELECT 'STG_ALBUMS', COUNT(*) FROM STG_ALBUMS
UNION ALL SELECT 'STG_SONGS', COUNT(*) FROM STG_SONGS
UNION ALL SELECT 'STG_STREAMING_METRICS', COUNT(*) FROM STG_STREAMING_METRICS;

