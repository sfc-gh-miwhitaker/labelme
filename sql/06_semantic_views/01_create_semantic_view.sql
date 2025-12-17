/*
 * LabelMe Demo - Semantic View for Cortex Analyst
 * Author: SE Community
 * Purpose: Create semantic view for natural language queries
 * Expires: 2026-01-16
 * 
 * Prerequisites: STG tables and views exist with data
 * 
 * This semantic view provides a unified interface for business users
 * to query music catalog performance using natural language.
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- SEMANTIC VIEW: Music Catalog Performance Analytics
-- ============================================================================
-- This view denormalizes our music catalog data to enable natural language
-- queries about artists, albums, songs, streaming performance, and contracts.
-- ============================================================================

CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
COMMENT = 'DEMO: LabelMe semantic view for Cortex Analyst | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    -- Artist Information
    a.artist_id,
    a.artist_name,
    a.country_code as artist_country,
    a.genre_primary as primary_genre,
    a.genre_secondary as secondary_genre,
    a.monthly_listeners,
    a.social_followers,
    a.quality_score as artist_data_quality_score,
    
    -- Contract Information
    a.label_signed_date,
    a.contract_end_date,
    DATEDIFF('day', CURRENT_DATE(), a.contract_end_date) as contract_days_remaining,
    CASE 
        WHEN a.contract_end_date < CURRENT_DATE() THEN 'Expired'
        WHEN a.contract_end_date < DATEADD('day', 30, CURRENT_DATE()) THEN 'Critical'
        WHEN a.contract_end_date < DATEADD('day', 90, CURRENT_DATE()) THEN 'Expiring Soon'
        ELSE 'Active'
    END as contract_status,
    
    -- Album Information
    al.album_id,
    al.album_title,
    al.album_title_english,
    al.release_date as album_release_date,
    al.album_type,
    al.total_tracks as album_track_count,
    al.label_name,
    al.distribution_region,
    DATEDIFF('day', al.release_date, CURRENT_DATE()) as days_since_album_release,
    
    -- Song Information
    s.song_id,
    s.song_title,
    s.song_title_english,
    s.duration_seconds,
    ROUND(s.duration_seconds / 60.0, 2) as duration_minutes,
    s.is_explicit,
    s.language_original as song_language,
    s.featuring_artists,
    CASE WHEN s.featuring_artists IS NOT NULL THEN TRUE ELSE FALSE END as is_collaboration,
    s.isrc_code,
    s.track_number,
    
    -- Streaming Metrics (aggregated across all platforms and regions)
    COALESCE(SUM(m.stream_count), 0) as total_streams,
    COALESCE(AVG(m.skip_rate), 0) as avg_skip_rate,
    COALESCE(AVG(m.save_rate), 0) as avg_save_rate,
    COALESCE(SUM(m.playlist_adds), 0) as total_playlist_adds,
    
    -- Performance Indicators
    CASE 
        WHEN COALESCE(SUM(m.stream_count), 0) > 1000000 THEN 'Hit'
        WHEN COALESCE(SUM(m.stream_count), 0) > 100000 THEN 'Popular'
        WHEN COALESCE(SUM(m.stream_count), 0) > 10000 THEN 'Growing'
        WHEN COALESCE(SUM(m.stream_count), 0) > 0 THEN 'Emerging'
        ELSE 'New Release'
    END as performance_tier,
    
    -- Engagement Score (custom metric: combines streams, saves, low skips)
    ROUND(
        (COALESCE(SUM(m.stream_count), 0) / 1000.0) * 
        (1 - COALESCE(AVG(m.skip_rate), 0)) * 
        (1 + COALESCE(AVG(m.save_rate), 0))
    , 2) as engagement_score,
    
    -- Temporal context
    YEAR(al.release_date) as release_year,
    QUARTER(al.release_date) as release_quarter,
    MONTHNAME(al.release_date) as release_month,
    
    -- Data freshness
    CURRENT_TIMESTAMP() as view_generated_at

FROM STG_ARTISTS a
LEFT JOIN STG_ALBUMS al ON a.artist_id = al.artist_id
LEFT JOIN STG_SONGS s ON al.album_id = s.album_id
LEFT JOIN STG_STREAMING_METRICS m ON s.song_id = m.song_id

GROUP BY 
    -- Group by all non-aggregated columns
    a.artist_id,
    a.artist_name,
    a.country_code,
    a.genre_primary,
    a.genre_secondary,
    a.monthly_listeners,
    a.social_followers,
    a.quality_score,
    a.label_signed_date,
    a.contract_end_date,
    al.album_id,
    al.album_title,
    al.album_title_english,
    al.release_date,
    al.album_type,
    al.total_tracks,
    al.label_name,
    al.distribution_region,
    s.song_id,
    s.song_title,
    s.song_title_english,
    s.duration_seconds,
    s.is_explicit,
    s.language_original,
    s.featuring_artists,
    s.isrc_code,
    s.track_number;

-- ============================================================================
-- GRANT ACCESS
-- ============================================================================
-- Grant access to PUBLIC role so all users can query the semantic view
GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG TO ROLE PUBLIC;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Semantic view created successfully' as status;

-- Show sample data
SELECT 
    artist_name,
    album_title,
    song_title,
    total_streams,
    performance_tier,
    contract_status,
    engagement_score
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
LIMIT 10;

-- Show row count
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT artist_id) as unique_artists,
    COUNT(DISTINCT album_id) as unique_albums,
    COUNT(DISTINCT song_id) as unique_songs
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG;

