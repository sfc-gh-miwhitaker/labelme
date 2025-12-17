/*
 * LabelMe Demo - Analytics Views
 * Author: SE Community
 * Purpose: Create views for reporting and dashboards
 * Expires: 2026-01-16
 * 
 * Prerequisites: STG tables exist with data
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- ARTIST PERFORMANCE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_ARTIST_PERFORMANCE
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
FROM STG_ARTISTS a
LEFT JOIN STG_ALBUMS al ON a.artist_id = al.artist_id
LEFT JOIN STG_SONGS s ON a.artist_id = s.artist_id
LEFT JOIN STG_STREAMING_METRICS m ON s.song_id = m.song_id
GROUP BY 1,2,3,4,5,6,7,8,13;

-- ============================================================================
-- CATALOG HEALTH VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_CATALOG_HEALTH
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
FROM STG_SONGS s
LEFT JOIN STG_ALBUMS al ON s.album_id = al.album_id
LEFT JOIN STG_ARTISTS a ON s.artist_id = a.artist_id;

-- ============================================================================
-- STREAMING TRENDS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_STREAMING_TRENDS
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
FROM STG_STREAMING_METRICS
GROUP BY 1,2,3;

-- ============================================================================
-- DATA QUALITY SCORECARD VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_DATA_QUALITY_SCORECARD
COMMENT = 'DEMO: Data quality metrics summary | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    'Artists' as entity,
    COUNT(*) as total_records,
    AVG(quality_score) as avg_quality_score,
    COUNT(CASE WHEN quality_score >= 90 THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN quality_score >= 90 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN country_code IS NOT NULL THEN 1 END) as standardized_count,
    CURRENT_TIMESTAMP() as measured_at
FROM STG_ARTISTS
UNION ALL
SELECT 
    'Songs' as entity,
    COUNT(*) as total_records,
    NULL as avg_quality_score,
    COUNT(CASE WHEN song_title = INITCAP(song_title) THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN song_title = INITCAP(song_title) THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN featuring_artists LIKE 'feat.%' OR featuring_artists IS NULL THEN 1 END) as standardized_count,
    CURRENT_TIMESTAMP() as measured_at
FROM STG_SONGS
UNION ALL
SELECT 
    'Streaming Metrics' as entity,
    COUNT(*) as total_records,
    NULL as avg_quality_score,
    COUNT(CASE WHEN platform IN ('Spotify', 'Apple Music', 'Amazon Music', 'YouTube Music', 'Tidal', 'Deezer', 'Pandora') THEN 1 END) as high_quality_count,
    ROUND(COUNT(CASE WHEN platform IN ('Spotify', 'Apple Music', 'Amazon Music', 'YouTube Music', 'Tidal', 'Deezer', 'Pandora') THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as high_quality_pct,
    COUNT(CASE WHEN LENGTH(region_code) = 2 THEN 1 END) as standardized_count,
    CURRENT_TIMESTAMP() as measured_at
FROM STG_STREAMING_METRICS;

-- ============================================================================
-- CONTRACT ALERTS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_CONTRACT_ALERTS
COMMENT = 'DEMO: Artist contracts requiring attention | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    artist_id,
    artist_name,
    country_code,
    contract_end_date,
    DATEDIFF('day', CURRENT_DATE(), contract_end_date) as days_until_expiry,
    CASE 
        WHEN contract_end_date < CURRENT_DATE() THEN 'EXPIRED'
        WHEN contract_end_date < DATEADD('day', 30, CURRENT_DATE()) THEN 'CRITICAL'
        WHEN contract_end_date < DATEADD('day', 60, CURRENT_DATE()) THEN 'WARNING'
        WHEN contract_end_date < DATEADD('day', 90, CURRENT_DATE()) THEN 'ATTENTION'
        ELSE 'OK'
    END as alert_level,
    monthly_listeners,
    social_followers
FROM STG_ARTISTS
WHERE contract_end_date < DATEADD('day', 90, CURRENT_DATE())
ORDER BY contract_end_date;

-- Verify creation
SHOW VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

