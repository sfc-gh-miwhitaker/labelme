/*
 * LabelMe Demo - Cortex AI Cleaning Functions
 * Author: SE Community
 * Purpose: Demonstrate Cortex COMPLETE and TRANSLATE for data cleaning
 * Expires: 2026-01-16
 * 
 * Prerequisites: RAW tables contain dirty data
 * 
 * NOTE: These queries can be expensive at scale. Use judiciously.
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;
USE WAREHOUSE SFE_LABELME_WH;

-- ============================================================================
-- EXAMPLE 1: Fix artist name spelling with CORTEX.COMPLETE
-- ============================================================================

-- Demo: Single name correction
SELECT 
    'Bettles' as dirty_name,
    TRIM(AI_COMPLETE(
        'mistral-7b',
        'Correct the spelling of this music artist name. Return ONLY the corrected name, nothing else: Bettles'
    )) as cleaned_name;

-- Demo: Fix capitalization
SELECT 
    'TAYLOR swift' as dirty_name,
    TRIM(AI_COMPLETE(
        'mistral-7b',
        'Fix the capitalization of this music artist name. Return ONLY the properly capitalized name: TAYLOR swift'
    )) as cleaned_name;

-- Demo: Multiple corrections at once
SELECT 
    artist_name as original,
    TRIM(AI_COMPLETE(
        'mistral-7b',
        'Correct the spelling and capitalization of this music artist name. Return ONLY the corrected name, nothing else: ' || artist_name
    )) as corrected
FROM RAW_ARTISTS
WHERE artist_name LIKE '%swift%' OR artist_name LIKE '%TAYLOR%'
LIMIT 5;

-- ============================================================================
-- EXAMPLE 2: Translate non-English content with CORTEX.TRANSLATE
-- ============================================================================

-- Demo: Japanese to English
SELECT 
    '君の名は' as japanese_title,
    SNOWFLAKE.CORTEX.TRANSLATE('君の名は', 'ja', 'en') as english_title;

-- Demo: Spanish to English
SELECT 
    'Despacito' as spanish_title,
    SNOWFLAKE.CORTEX.TRANSLATE('La vida es bella', 'es', 'en') as english_title;

-- Demo: Translate song titles
SELECT 
    song_title as original,
    language_original,
    CASE 
        WHEN language_original = 'es' THEN SNOWFLAKE.CORTEX.TRANSLATE(song_title, 'es', 'en')
        WHEN language_original = 'fr' THEN SNOWFLAKE.CORTEX.TRANSLATE(song_title, 'fr', 'en')
        WHEN language_original = 'de' THEN SNOWFLAKE.CORTEX.TRANSLATE(song_title, 'de', 'en')
        WHEN language_original = 'ja' THEN SNOWFLAKE.CORTEX.TRANSLATE(song_title, 'ja', 'en')
        WHEN language_original = 'ko' THEN SNOWFLAKE.CORTEX.TRANSLATE(song_title, 'ko', 'en')
        ELSE song_title
    END as english_translation
FROM RAW_SONGS
WHERE language_original != 'en'
LIMIT 10;

-- ============================================================================
-- EXAMPLE 3: Genre standardization with CORTEX.COMPLETE
-- ============================================================================

-- Demo: Standardize messy genre names
SELECT 
    genre_primary as original_genre,
    TRIM(AI_COMPLETE(
        'mistral-7b',
        'Standardize this music genre name to a standard format (e.g., Rock, Pop, Hip-Hop, R&B, Country, Electronic, Jazz, Classical). Return ONLY the standardized genre name: ' || genre_primary
    )) as standardized_genre
FROM RAW_ARTISTS
WHERE genre_primary IS NOT NULL
LIMIT 10;

-- ============================================================================
-- EXAMPLE 4: Batch processing with CORTEX (for production)
-- ============================================================================

-- For larger datasets, process in batches to manage costs
-- This example shows the pattern:

/*
-- Create a staging table for batch results
CREATE OR REPLACE TEMPORARY TABLE cortex_batch_results AS
SELECT 
    artist_id,
    artist_name as original_name,
    TRIM(AI_COMPLETE(
        'mistral-7b',
        'Fix the spelling and capitalization of this artist name. Return ONLY the corrected name: ' || artist_name
    )) as cleaned_name
FROM RAW_ARTISTS
WHERE artist_id BETWEEN 1 AND 100;  -- Process 100 at a time

-- Merge results
MERGE INTO STG_ARTISTS t
USING cortex_batch_results s
ON t.artist_id = s.artist_id
WHEN MATCHED THEN UPDATE SET 
    artist_name = s.cleaned_name,
    processed_at = CURRENT_TIMESTAMP();
*/

-- ============================================================================
-- COST ESTIMATION
-- ============================================================================

-- Cortex charges per token. Estimate costs before large runs:
SELECT 
    COUNT(*) as total_records,
    AVG(LENGTH(artist_name)) as avg_name_length,
    SUM(LENGTH(artist_name)) as total_characters,
    -- Rough estimate: ~4 chars per token, ~$0.0001 per 1K tokens for mistral-7b
    ROUND(SUM(LENGTH(artist_name)) / 4 / 1000 * 0.0001, 4) as estimated_cost_usd
FROM RAW_ARTISTS;

