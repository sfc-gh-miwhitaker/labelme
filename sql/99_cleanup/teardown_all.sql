/*
 * LabelMe Demo - Complete Teardown
 * Author: SE Community
 * Purpose: Remove all demo objects
 * Expires: 2026-01-16
 * 
 * WARNING: This will permanently delete all demo data and objects!
 */

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 1: Suspend and drop tasks (must be done first)
-- ============================================================================
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK SUSPEND;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK;

-- ============================================================================
-- STEP 2: Drop Streamlit app
-- ============================================================================
DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD;

-- ============================================================================
-- STEP 3: Drop project schemas (CASCADE drops all objects within)
-- ============================================================================
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.LABELME CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS CASCADE;

-- ============================================================================
-- STEP 4: Drop warehouse
-- ============================================================================
DROP WAREHOUSE IF EXISTS SFE_LABELME_WH;

-- ============================================================================
-- STEP 5: Drop API integration (uncomment if not shared)
-- ============================================================================
-- NOTE: Only drop if this integration is not used by other projects
-- DROP API INTEGRATION IF EXISTS SFE_LABELME_GIT_API_INTEGRATION;

