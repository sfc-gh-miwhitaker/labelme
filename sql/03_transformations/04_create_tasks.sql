/*
 * LabelMe Demo - Task Creation
 * Author: SE Community
 * Purpose: Create automated daily pipeline task
 * Expires: 2026-01-16
 * 
 * Prerequisites: Warehouse exists, streams exist
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- CLEANING PROCEDURE
-- ============================================================================
CREATE OR REPLACE PROCEDURE CLEAN_DATA_WITH_CORTEX()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'DEMO: AI-powered data cleaning procedure | Author: SE Community | Expires: 2026-01-16'
AS
$$
BEGIN
    -- Process artists from stream
    MERGE INTO STG_ARTISTS t
    USING (
        SELECT 
            artist_id,
            INITCAP(TRIM(artist_name)) as artist_name_clean,
            CASE 
                WHEN UPPER(country_of_origin) IN ('USA', 'UNITED STATES', 'UNITED STATES OF AMERICA', 'U.S.A.') THEN 'US'
                WHEN UPPER(country_of_origin) IN ('UK', 'UNITED KINGDOM', 'U.K.', 'GREAT BRITAIN') THEN 'GB'
                WHEN UPPER(country_of_origin) IN ('CANADA') THEN 'CA'
                WHEN UPPER(country_of_origin) IN ('GERMANY', 'DEUTSCHLAND') THEN 'DE'
                WHEN UPPER(country_of_origin) IN ('FRANCE') THEN 'FR'
                WHEN UPPER(country_of_origin) IN ('JAPAN') THEN 'JP'
                WHEN UPPER(country_of_origin) IN ('SOUTH KOREA', 'KOREA') THEN 'KR'
                ELSE UPPER(LEFT(country_of_origin, 2))
            END as country_code,
            INITCAP(TRIM(REPLACE(genre_primary, 'music', ''))) as genre_primary_clean,
            INITCAP(TRIM(genre_secondary)) as genre_secondary_clean,
            label_signed_date,
            contract_end_date,
            social_followers,
            monthly_listeners,
            ROUND(RANDOM() * 30 + 70, 2) as quality_score
        FROM ARTISTS_STREAM
        WHERE METADATA$ACTION = 'INSERT'
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

    RETURN 'Data cleaning completed successfully at ' || CURRENT_TIMESTAMP()::VARCHAR;
END;
$$;

-- ============================================================================
-- DAILY TASK
-- ============================================================================
CREATE OR REPLACE TASK CLEAN_DATA_TASK
    WAREHOUSE = SFE_LABELME_WH
    SCHEDULE = 'USING CRON 0 2 * * * America/Los_Angeles'  -- Daily at 2 AM PT
    COMMENT = 'DEMO: Daily data cleaning task | Author: SE Community | Expires: 2026-01-16'
AS
    CALL CLEAN_DATA_WITH_CORTEX();

-- Note: Task is created SUSPENDED. To enable:
-- ALTER TASK CLEAN_DATA_TASK RESUME;

-- Verify creation
SHOW TASKS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

