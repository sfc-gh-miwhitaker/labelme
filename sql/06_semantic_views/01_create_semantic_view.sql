/*
 * LabelMe Demo - Semantic View for Cortex Analyst
 * Author: SE Community
 * Purpose: Create semantic view for natural language queries
 * Expires: 2026-01-16
 * 
 * Prerequisites: STG tables exist with data
 * 
 * This semantic view provides a unified interface for business users
 * to query music catalog performance using natural language.
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

-- ============================================================================
-- BASE VIEW: Denormalized Music Catalog
-- ============================================================================
CREATE OR REPLACE VIEW V_LABELME_CATALOG_BASE
COMMENT = 'DEMO: Denormalized view combining artists, albums, songs, and streaming metrics | Author: SE Community | Expires: 2026-01-16'
AS
SELECT 
    a.artist_id,
    a.artist_name,
    a.country_code as artist_country,
    a.genre_primary as primary_genre,
    a.genre_secondary as secondary_genre,
    a.monthly_listeners,
    a.social_followers,
    a.label_signed_date,
    a.contract_end_date,
    DATEDIFF('day', CURRENT_DATE(), a.contract_end_date) as contract_days_remaining,
    CASE 
        WHEN a.contract_end_date < CURRENT_DATE() THEN 'Expired'
        WHEN DATEDIFF('day', CURRENT_DATE(), a.contract_end_date) <= 30 THEN 'Critical'
        WHEN DATEDIFF('day', CURRENT_DATE(), a.contract_end_date) <= 90 THEN 'Expiring Soon'
        WHEN DATEDIFF('day', CURRENT_DATE(), a.contract_end_date) <= 180 THEN 'Renewal Upcoming'
        ELSE 'Active'
    END as contract_status,
    a.quality_score as artist_data_quality_score,
    
    al.album_id,
    al.album_title,
    al.album_title_english,
    al.release_date as album_release_date,
    DATEDIFF('day', al.release_date, CURRENT_DATE()) as days_since_album_release,
    al.album_type,
    al.total_tracks as album_track_count,
    al.label_name,
    al.distribution_region,
    
    s.song_id,
    s.song_title,
    s.song_title_english,
    s.duration_seconds,
    s.is_explicit,
    s.language_original,
    s.featuring_artists,
    CASE WHEN s.featuring_artists IS NOT NULL THEN TRUE ELSE FALSE END as is_collaboration,
    s.isrc_code,
    s.track_number,
    
    m.metric_id,
    m.platform,
    m.region_code,
    m.metric_date,
    m.stream_count,
    m.skip_rate,
    m.save_rate,
    m.playlist_adds
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS a
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS al 
    ON a.artist_id = al.artist_id
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS s 
    ON al.album_id = s.album_id
LEFT JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS m 
    ON s.song_id = m.song_id;

-- ============================================================================
-- AGGREGATED VIEW: Performance Metrics
-- ============================================================================
CREATE OR REPLACE VIEW V_LABELME_CATALOG_AGGREGATED
COMMENT = 'DEMO: Aggregated performance metrics with engagement scores | Author: SE Community | Expires: 2026-01-16'
AS
SELECT
    artist_id,
    artist_name,
    artist_country,
    primary_genre,
    secondary_genre,
    monthly_listeners,
    social_followers,
    label_signed_date,
    contract_end_date,
    contract_days_remaining,
    contract_status,
    artist_data_quality_score,
    
    album_id,
    album_title,
    album_title_english,
    album_release_date,
    days_since_album_release,
    album_type,
    album_track_count,
    label_name,
    distribution_region,
    
    song_id,
    song_title,
    song_title_english,
    duration_seconds,
    is_explicit,
    language_original,
    featuring_artists,
    is_collaboration,
    isrc_code,
    track_number,
    
    SUM(stream_count) as total_streams,
    AVG(skip_rate) as avg_skip_rate,
    AVG(save_rate) as avg_save_rate,
    SUM(playlist_adds) as total_playlist_adds,
    
    (SUM(stream_count) * (1 - AVG(skip_rate)) * (1 + AVG(save_rate)) * LN(1 + SUM(playlist_adds))) as engagement_score,
    
    CASE 
        WHEN (SUM(stream_count) * (1 - AVG(skip_rate)) * (1 + AVG(save_rate)) * LN(1 + SUM(playlist_adds))) > 1000 THEN 'Hit'
        WHEN (SUM(stream_count) * (1 - AVG(skip_rate)) * (1 + AVG(save_rate)) * LN(1 + SUM(playlist_adds))) > 500 THEN 'Popular'
        WHEN (SUM(stream_count) * (1 - AVG(skip_rate)) * (1 + AVG(save_rate)) * LN(1 + SUM(playlist_adds))) > 100 THEN 'Growing'
        ELSE 'Emerging'
    END as performance_tier
FROM V_LABELME_CATALOG_BASE
GROUP BY 
    artist_id, artist_name, artist_country, primary_genre, secondary_genre,
    monthly_listeners, social_followers, label_signed_date, contract_end_date,
    contract_days_remaining, contract_status, artist_data_quality_score,
    album_id, album_title, album_title_english, album_release_date, 
    days_since_album_release, album_type, album_track_count, label_name, distribution_region,
    song_id, song_title, song_title_english, duration_seconds, is_explicit,
    language_original, featuring_artists, is_collaboration, isrc_code, track_number;

-- ============================================================================
-- SEMANTIC VIEW: Music Catalog Performance Analytics
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_LABELME_CATALOG
TABLES (
    V_LABELME_CATALOG_AGGREGATED
)
FACTS (
  V_LABELME_CATALOG_AGGREGATED.monthly_listeners as MONTHLY_LISTENERS
    comment='Number of unique monthly listeners on streaming platforms. Higher values indicate larger audience reach. Synonyms: monthly listeners, listeners, audience size, monthly audience, listener count.',
  
  V_LABELME_CATALOG_AGGREGATED.social_followers as SOCIAL_FOLLOWERS
    comment='Total social media followers across all platforms (Instagram, Twitter, TikTok, etc). Indicates social media reach and fan engagement. Synonyms: followers, fans, social media followers, social following, social reach.',
  
  V_LABELME_CATALOG_AGGREGATED.artist_data_quality_score as ARTIST_DATA_QUALITY_SCORE
    comment='Data quality score (0-100) for artist metadata completeness and accuracy. Higher scores indicate cleaner data. Synonyms: data quality, quality score, metadata quality, artist data quality.',
  
  V_LABELME_CATALOG_AGGREGATED.album_track_count as ALBUM_TRACK_COUNT
    comment='Number of tracks on the album. LP albums typically have 10-15 tracks, EPs have 4-7 tracks. Synonyms: track count, number of tracks, tracks on album, song count.',
  
  V_LABELME_CATALOG_AGGREGATED.duration_seconds as DURATION_SECONDS
    comment='Song duration in seconds. Typical pop songs are 180-240 seconds (3-4 minutes). Synonyms: duration, length, song length, runtime, play time.',
  
  V_LABELME_CATALOG_AGGREGATED.total_streams as TOTAL_STREAMS
    comment='Total number of times the song was streamed across all platforms and regions. Aggregated metric indicating overall popularity. Synonyms: streams, plays, total plays, stream count, total streams.',
  
  V_LABELME_CATALOG_AGGREGATED.avg_skip_rate as AVG_SKIP_RATE
    comment='Average percentage of listeners who skipped the song before completion (0-1, where 0.20 = 20%). Lower values indicate better listener retention. Synonyms: skip rate, skips, skip percentage, listener drop-off.',
  
  V_LABELME_CATALOG_AGGREGATED.avg_save_rate as AVG_SAVE_RATE
    comment='Average percentage of listeners who saved the song to their library (0-1, where 0.15 = 15%). Higher values indicate strong listener affinity. Synonyms: save rate, saves, add to library rate, library adds.',
  
  V_LABELME_CATALOG_AGGREGATED.total_playlist_adds as TOTAL_PLAYLIST_ADDS
    comment='Total number of times the song was added to user-created playlists across all platforms. High playlist adds indicate viral potential. Synonyms: playlist adds, added to playlists, playlist inclusion.',
  
  V_LABELME_CATALOG_AGGREGATED.engagement_score as ENGAGEMENT_SCORE
    comment='Composite engagement score calculated from streams, skip rate, save rate, and playlist adds. Higher scores indicate stronger overall listener engagement and hit potential. Synonyms: engagement, engagement metric, performance score, hit score.',
  
  V_LABELME_CATALOG_AGGREGATED.contract_days_remaining as CONTRACT_DAYS_REMAINING
    comment='Number of days until artist contract expires. Negative values indicate expired contracts. Critical for renewal planning. Synonyms: days remaining, days to expiration, days until renewal.',
  
  V_LABELME_CATALOG_AGGREGATED.days_since_album_release as DAYS_SINCE_ALBUM_RELEASE
    comment='Number of days since album was released. Use for analyzing new releases vs catalog performance. Synonyms: days since release, album age, time since release.'
)
DIMENSIONS (
  V_LABELME_CATALOG_AGGREGATED.artist_id as ARTIST_ID
    comment='Unique artist identifier. Use for joining or tracking specific artists. Synonyms: artist ID, artist identifier.',
  
  V_LABELME_CATALOG_AGGREGATED.artist_name as ARTIST_NAME
    comment='Name of the artist or band (e.g., "Taylor Swift", "The Beatles", "BTS"). Synonyms: artist, artist name, performer, musician, band name.',
  
  V_LABELME_CATALOG_AGGREGATED.artist_country as ARTIST_COUNTRY
    comment='Two-letter country code of artist origin (ISO 3166-1 alpha-2, e.g., US, GB, KR, JP). Synonyms: country, artist country, origin, nationality, home country.',
  
  V_LABELME_CATALOG_AGGREGATED.primary_genre as PRIMARY_GENRE
    comment='Primary musical genre (e.g., Pop, Hip-Hop, Rock, R&B, Country, Electronic). Synonyms: genre, primary genre, music genre, main genre, style.',
  
  V_LABELME_CATALOG_AGGREGATED.secondary_genre as SECONDARY_GENRE
    comment='Secondary or sub-genre classification. Synonyms: secondary genre, sub-genre, secondary style.',
  
  V_LABELME_CATALOG_AGGREGATED.label_signed_date as LABEL_SIGNED_DATE
    comment='Date the artist signed with the record label. Use for tracking contract tenure. Synonyms: signed date, contract start, signing date, deal date.',
  
  V_LABELME_CATALOG_AGGREGATED.contract_end_date as CONTRACT_END_DATE
    comment='Contract expiration date. Critical for renewal planning and A&R strategy. Synonyms: contract end, contract expiration, contract expires, end date, expiration date.',
  
  V_LABELME_CATALOG_AGGREGATED.contract_status as CONTRACT_STATUS
    comment='Contract status category: Expired, Critical (<=30 days), Expiring Soon (<=90 days), Renewal Upcoming (<=180 days), or Active. Synonyms: status, contract status, contract state.',
  
  V_LABELME_CATALOG_AGGREGATED.album_id as ALBUM_ID
    comment='Unique album identifier. Use for joining or tracking specific albums. Synonyms: album ID, album identifier.',
  
  V_LABELME_CATALOG_AGGREGATED.album_title as ALBUM_TITLE
    comment='Title of the album or record. Synonyms: album, album name, album title, record title, release name.',
  
  V_LABELME_CATALOG_AGGREGATED.album_title_english as ALBUM_TITLE_ENGLISH
    comment='English translation of album title for non-English releases. NULL if original is English. Synonyms: english title, translated title.',
  
  V_LABELME_CATALOG_AGGREGATED.album_release_date as ALBUM_RELEASE_DATE
    comment='Album release date. Use for analyzing new releases vs catalog performance. Synonyms: release date, released on, came out, launch date.',
  
  V_LABELME_CATALOG_AGGREGATED.album_type as ALBUM_TYPE
    comment='Album format type: LP (full-length album), EP (extended play), or Single. Synonyms: type, format, release type, album format.',
  
  V_LABELME_CATALOG_AGGREGATED.label_name as LABEL_NAME
    comment='Record label that released the album. Synonyms: label, record label, music label, publisher.',
  
  V_LABELME_CATALOG_AGGREGATED.distribution_region as DISTRIBUTION_REGION
    comment='Primary distribution region or territory for the album release. Synonyms: region, distribution, territory, market.',
  
  V_LABELME_CATALOG_AGGREGATED.song_id as SONG_ID
    comment='Unique song identifier. Use for joining or tracking specific songs. Synonyms: song ID, song identifier, track ID.',
  
  V_LABELME_CATALOG_AGGREGATED.song_title as SONG_TITLE
    comment='Title of the song or track. Synonyms: song, track, song title, track title, song name, track name.',
  
  V_LABELME_CATALOG_AGGREGATED.song_title_english as SONG_TITLE_ENGLISH
    comment='English translation of song title for non-English songs. NULL if original is English. Synonyms: english title, translated title.',
  
  V_LABELME_CATALOG_AGGREGATED.is_explicit as IS_EXPLICIT
    comment='Whether the song contains explicit content (TRUE/FALSE). Explicit songs may have restricted airplay. Synonyms: explicit, explicit content, parental advisory.',
  
  V_LABELME_CATALOG_AGGREGATED.language_original as LANGUAGE_ORIGINAL
    comment='Original language of the song (e.g., "en" for English, "es" for Spanish, "ko" for Korean). Synonyms: language, original language, song language.',
  
  V_LABELME_CATALOG_AGGREGATED.featuring_artists as FEATURING_ARTISTS
    comment='Featured or collaborating artists (e.g., "feat. Drake", "feat. Ariana Grande"). NULL if solo track. Synonyms: featuring, featured artists, collaboration, feat, collab, guest artists.',
  
  V_LABELME_CATALOG_AGGREGATED.is_collaboration as IS_COLLABORATION
    comment='Boolean flag indicating whether song is a collaboration with featured artists (TRUE) or solo (FALSE). Synonyms: collaboration flag, is collab, has features.',
  
  V_LABELME_CATALOG_AGGREGATED.isrc_code as ISRC_CODE
    comment='International Standard Recording Code - unique identifier for sound recordings. Synonyms: ISRC, code, recording code.',
  
  V_LABELME_CATALOG_AGGREGATED.track_number as TRACK_NUMBER
    comment='Track position on the album (1 = first track, etc.). Synonyms: track number, track position, album position, track order.',
  
  V_LABELME_CATALOG_AGGREGATED.performance_tier as PERFORMANCE_TIER
    comment='Performance tier classification: Hit, Popular, Growing, or Emerging based on engagement score thresholds. Synonyms: tier, performance level, hit status.'
)
COMMENT = 'DEMO: LabelMe music catalog analytics for Cortex Analyst. Ask about artist performance, contract renewals, streaming metrics, album releases, and genre trends. Author: SE Community | Expires: 2026-01-16'
WITH EXTENSION (CA = '{
  "verified_queries": [
    {
      "name": "Contract expirations",
      "question": "Which artists have contracts expiring in the next 90 days?",
      "sql": "SELECT artist_name, contract_end_date, contract_days_remaining, monthly_listeners, engagement_score FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG WHERE contract_status IN (''Critical'', ''Expiring Soon'') GROUP BY artist_name, contract_end_date, contract_days_remaining, monthly_listeners, engagement_score ORDER BY contract_days_remaining ASC LIMIT 20"
    },
    {
      "name": "Top streaming songs",
      "question": "What are the top 10 songs by total streams?",
      "sql": "SELECT song_title, artist_name, total_streams, avg_skip_rate, engagement_score FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG WHERE song_id IS NOT NULL GROUP BY song_title, artist_name, total_streams, avg_skip_rate, engagement_score ORDER BY total_streams DESC LIMIT 10"
    },
    {
      "name": "Genre performance",
      "question": "Which genres have the most total streams?",
      "sql": "SELECT primary_genre, COUNT(DISTINCT artist_name) as artist_count, SUM(total_streams) as genre_streams FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG WHERE primary_genre IS NOT NULL GROUP BY primary_genre ORDER BY genre_streams DESC"
    },
    {
      "name": "Recent album releases",
      "question": "Which albums were released in the last 6 months?",
      "sql": "SELECT album_title, artist_name, album_release_date, album_type, days_since_album_release FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG WHERE days_since_album_release <= 180 AND album_id IS NOT NULL GROUP BY album_title, artist_name, album_release_date, album_type, days_since_album_release ORDER BY album_release_date DESC LIMIT 20"
    },
    {
      "name": "Collaboration analysis",
      "question": "Which artists have the most collaborations?",
      "sql": "SELECT artist_name, COUNT(DISTINCT song_title) as collaboration_count, AVG(engagement_score) as avg_collaboration_engagement FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG WHERE is_collaboration = TRUE GROUP BY artist_name ORDER BY collaboration_count DESC LIMIT 20"
    }
  ]
}');

-- ============================================================================
-- GRANT ACCESS
-- ============================================================================
GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_BASE TO ROLE PUBLIC;
GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_AGGREGATED TO ROLE PUBLIC;
GRANT SELECT ON SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG TO ROLE PUBLIC;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Base view row count: ' || COUNT(*) as verification 
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_BASE;

SELECT 'Aggregated view row count: ' || COUNT(*) as verification
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_AGGREGATED;

SELECT 'Semantic view created successfully' as status;
SHOW SEMANTIC VIEWS LIKE 'SV_LABELME_CATALOG';

SELECT 'Sample data from semantic view:' as info;
SELECT * FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG LIMIT 5;
