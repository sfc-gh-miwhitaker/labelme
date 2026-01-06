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
-- STEP 1: SET CONTEXT
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 2: CREATE WAREHOUSE (needed before any operations)
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS SFE_LABELME_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

USE WAREHOUSE SFE_LABELME_WH;

-- ============================================================================
-- STEP 3: EXPIRATION CHECK (HALTS EXECUTION IF EXPIRED)
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
-- STEP 4: CREATE DATABASE AND SCHEMAS
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
-- STEP 5: CREATE API INTEGRATION FOR GITHUB
-- ============================================================================
CREATE OR REPLACE API INTEGRATION SFE_LABELME_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: GitHub API integration for LabelMe | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STEP 6: CREATE GIT REPOSITORY AND FETCH
-- ============================================================================
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo
    API_INTEGRATION = SFE_LABELME_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/labelme'
    COMMENT = 'DEMO: LabelMe source repository | Author: SE Community | Expires: 2026-01-16';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo FETCH;

-- ============================================================================
-- STEP 7: EXECUTE SQL SCRIPTS FROM GIT REPOSITORY
-- ============================================================================

-- 7.1: Create tables
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/02_data/01_create_tables.sql;

-- 7.2: Load sample data
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/02_data/02_load_sample_data.sql;

-- 7.3: Create streams for CDC
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/01_create_streams.sql;

-- 7.4: Initial data cleaning (RAW to STG)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/02_initial_data_clean.sql;

-- 7.5: Create analytics views
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/03_create_views.sql;

-- 7.6: Create scheduled tasks
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/04_create_tasks.sql;

-- ============================================================================
-- OPTIONAL: Modern Alternative - Dynamic Tables (replaces Streams + Tasks)
-- ============================================================================
-- UNCOMMENT THE LINE BELOW to use Dynamic Tables instead of Streams + Tasks
-- This modern pattern offers 60% code reduction and automatic optimization
-- For migration guide, see sql/03_transformations/05_create_dynamic_tables.sql
-- ============================================================================
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/05_create_dynamic_tables.sql;

-- 7.7: Create Streamlit dashboard
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/05_streamlit/01_create_streamlit.sql;

-- 7.8: Create semantic view for Cortex Analyst
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/06_semantic_views/01_create_semantic_view.sql;

-- 7.9: Create Snowflake Intelligence agent (requires ACCOUNTADMIN)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/06_semantic_views/03_create_intelligence_agent.sql;

-- ============================================================================
-- STEP 8: GRANT PERMISSIONS
-- ============================================================================
-- SECURITY NOTE: Configure grants based on your organization's security model
-- Example grants are provided below - uncomment and modify for your roles
-- ============================================================================

-- Example: Grant warehouse usage
-- GRANT USAGE ON WAREHOUSE SFE_LABELME_WH TO ROLE <your_role>;

-- Example: Grant database and schema access
-- GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE <your_role>;
-- GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE <your_role>;
-- GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE <your_role>;

-- Example: Grant table and view access
-- GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE <your_role>;
-- GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME TO ROLE <your_role>;

-- Example: Grant Streamlit access
-- GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD TO ROLE <your_role>;

-- Example: Grant semantic view access
-- GRANT SELECT ON SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG TO ROLE <your_role>;

-- Example: Grant agent access
-- GRANT USAGE ON AGENT SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.LABELME_CATALOG_AGENT TO ROLE <your_role>;
-- GRANT APPLICATION ROLE SNOWFLAKE.CORTEX_USER TO ROLE <your_role>;

-- Example: Grant Snowflake Intelligence access
-- GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE <your_role>;

-- ============================================================================
-- STEP 9: VERIFICATION
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
-- 3. Test the Intelligence Agent:
--    - Navigate to: AI & ML → Agents → Snowflake Intelligence
--    - Select: LabelMe Catalog Agent
--    - Try: "Which artists have contracts expiring in the next 90 days?"
-- 4. Explore the data using the views created
-- 5. To enable the daily task: ALTER TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK RESUME;
-- 
-- For cleanup, run:
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/99_cleanup/teardown_all.sql;
-- 
-- ============================================================================
