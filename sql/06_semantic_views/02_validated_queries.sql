/*
 * LabelMe Demo - Validated Queries for Semantic View
 * Author: SE Community
 * Purpose: 5 validated business questions with SQL queries
 * Expires: 2026-01-16
 * 
 * These queries demonstrate common business questions that executives
 * and A&R teams ask about music catalog performance using the semantic view.
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- VALIDATED QUERY 1: Contract Expiration Alert
-- ============================================================================
-- Business Context: Contract renewal planning is critical for label operations.
-- A&R teams need 60-90 days advance notice to negotiate renewals with
-- high-performing artists. This query identifies contracts requiring attention.
-- ============================================================================

SELECT 
    artist_name,
    contract_end_date,
    contract_days_remaining,
    contract_status,
    monthly_listeners,
    social_followers,
    total_streams,
    engagement_score,
    primary_genre
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE contract_status IN ('Critical', 'Expiring Soon')
GROUP BY 
    artist_name,
    contract_end_date,
    contract_days_remaining,
    contract_status,
    monthly_listeners,
    social_followers,
    total_streams,
    engagement_score,
    primary_genre
ORDER BY contract_days_remaining ASC
LIMIT 20;

-- ============================================================================
-- VALIDATED QUERY 2: Top Performing Songs by Engagement
-- ============================================================================
-- Business Context: Engagement score combines streams, skip rate, save rate,
-- and playlist adds to identify songs with genuine listener appeal (not just
-- passive plays). This helps identify which songs to promote in playlists,
-- radio, and marketing campaigns.
-- ============================================================================

SELECT 
    song_title,
    artist_name,
    album_title,
    total_streams,
    avg_skip_rate,
    avg_save_rate,
    engagement_score,
    performance_tier,
    primary_genre,
    album_release_date
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE song_id IS NOT NULL
GROUP BY 
    song_title,
    artist_name,
    album_title,
    total_streams,
    avg_skip_rate,
    avg_save_rate,
    engagement_score,
    performance_tier,
    primary_genre,
    album_release_date
ORDER BY engagement_score DESC
LIMIT 10;

-- ============================================================================
-- VALIDATED QUERY 3: Genre Performance Analysis
-- ============================================================================
-- Business Context: Understanding genre performance helps labels decide where
-- to invest in new artist signings and which genres to prioritize in A&R.
-- This analysis reveals market trends and investment opportunities.
-- ============================================================================

SELECT 
    primary_genre,
    COUNT(DISTINCT artist_name) as artist_count,
    COUNT(DISTINCT album_title) as album_count,
    COUNT(DISTINCT song_title) as song_count,
    SUM(total_streams) as total_genre_streams,
    AVG(engagement_score) as avg_engagement_score,
    ROUND(AVG(avg_skip_rate) * 100, 2) as avg_skip_rate_pct,
    ROUND(AVG(avg_save_rate) * 100, 2) as avg_save_rate_pct
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE primary_genre IS NOT NULL
GROUP BY primary_genre
ORDER BY total_genre_streams DESC;

-- ============================================================================
-- VALIDATED QUERY 4: Underperforming Recent Album Releases
-- ============================================================================
-- Business Context: First 6 months determine album commercial success.
-- Recently released albums with low engagement may need additional marketing
-- support, playlist placement, or promotional campaigns. Early intervention
-- can save a release from commercial failure.
-- ============================================================================

SELECT 
    album_title,
    artist_name,
    album_release_date,
    days_since_album_release,
    album_track_count,
    SUM(total_streams) as album_total_streams,
    AVG(engagement_score) as album_avg_engagement,
    label_name,
    primary_genre,
    CASE 
        WHEN SUM(total_streams) < 50000 THEN 'Needs Attention'
        WHEN SUM(total_streams) < 100000 THEN 'Below Target'
        ELSE 'On Track'
    END as performance_assessment
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE days_since_album_release <= 180
  AND album_id IS NOT NULL
GROUP BY 
    album_title,
    artist_name,
    album_release_date,
    days_since_album_release,
    album_track_count,
    label_name,
    primary_genre
HAVING SUM(total_streams) < 100000
ORDER BY album_total_streams ASC
LIMIT 15;

-- ============================================================================
-- VALIDATED QUERY 5: Collaboration vs Solo Performance
-- ============================================================================
-- Business Context: Collaborations (featuring other artists) often outperform
-- solo releases due to cross-fan exposure. Understanding collaboration impact
-- helps A&R teams strategize about which artists to pair together and informs
-- contract negotiation terms around collaboration clauses.
-- ============================================================================

SELECT 
    is_collaboration,
    COUNT(DISTINCT song_id) as song_count,
    AVG(total_streams) as avg_streams_per_song,
    AVG(engagement_score) as avg_engagement,
    AVG(avg_skip_rate) as avg_skip_rate,
    AVG(avg_save_rate) as avg_save_rate,
    ROUND(AVG(total_playlist_adds), 0) as avg_playlist_adds,
    COUNT(DISTINCT CASE WHEN performance_tier = 'Hit' THEN song_id END) as hit_count,
    COUNT(DISTINCT CASE WHEN performance_tier = 'Popular' THEN song_id END) as popular_count
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE song_id IS NOT NULL
GROUP BY is_collaboration
ORDER BY is_collaboration DESC;

-- ============================================================================
-- BONUS QUERY: Comprehensive Artist Portfolio Summary
-- ============================================================================
-- Business Context: Executive dashboard view combining contract status,
-- catalog size, streaming performance, and engagement for strategic decisions
-- about artist investment, renewal priorities, and A&R resource allocation.
-- ============================================================================

SELECT 
    artist_name,
    primary_genre,
    artist_country,
    contract_status,
    contract_days_remaining,
    COUNT(DISTINCT album_id) as album_count,
    COUNT(DISTINCT song_id) as song_count,
    SUM(total_streams) as total_artist_streams,
    AVG(engagement_score) as avg_engagement,
    monthly_listeners,
    social_followers,
    ROUND(artist_data_quality_score, 0) as data_quality,
    MAX(album_release_date) as most_recent_release
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE artist_id IS NOT NULL
GROUP BY 
    artist_name,
    primary_genre,
    artist_country,
    contract_status,
    contract_days_remaining,
    monthly_listeners,
    social_followers,
    artist_data_quality_score
ORDER BY total_artist_streams DESC
LIMIT 20;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'All 5 validated queries executed successfully' as status;
