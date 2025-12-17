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
 * This script sets up Git integration then executes SQL files from the repo.
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
-- STEP 2: CREATE WAREHOUSE (needed before Git operations)
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS SFE_LABELME_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

USE WAREHOUSE SFE_LABELME_WH;

-- ============================================================================
-- STEP 3: CREATE DATABASE AND SCHEMAS
-- ============================================================================
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'Shared database for SE demo projects';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS
    COMMENT = 'DEMO: Git repository for LabelMe project | Author: SE Community | Expires: 2026-01-16';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'Shared semantic views for Cortex Analyst agents';

-- ============================================================================
-- STEP 4: CREATE API INTEGRATION FOR GITHUB
-- ============================================================================
CREATE OR REPLACE API INTEGRATION SFE_LABELME_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: GitHub API integration for LabelMe | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 5: CREATE GIT REPOSITORY AND FETCH
-- ============================================================================
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo
    API_INTEGRATION = SFE_LABELME_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/labelme'
    COMMENT = 'DEMO: LabelMe source repository | Author: SE Community | Expires: 2026-01-16';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo FETCH;

-- ============================================================================
-- STEP 6: EXECUTE SQL SCRIPTS FROM GIT REPOSITORY
-- ============================================================================

-- 6.1: Create tables
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/02_data/01_create_tables.sql;

-- 6.2: Load sample data
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/02_data/02_load_sample_data.sql;

-- 6.3: Create streams for CDC
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/01_create_streams.sql;

-- 6.4: Initial data cleaning (RAW to STG)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/02_initial_data_clean.sql;

-- 6.5: Create analytics views
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/03_create_views.sql;

-- 6.6: Create scheduled tasks
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/04_create_tasks.sql;

-- 6.7: Create Streamlit dashboard
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/05_streamlit/01_create_streamlit.sql;

-- ============================================================================
-- STEP 7: GRANT PERMISSIONS
-- ============================================================================
GRANT USAGE ON WAREHOUSE SFE_LABELME_WH TO ROLE PUBLIC;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE PUBLIC;
GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD TO ROLE PUBLIC;

-- ============================================================================
-- STEP 8: VERIFICATION
-- ============================================================================
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
-- For cleanup, run:
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/99_cleanup/teardown_all.sql;
-- 
-- ============================================================================
