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
-- STEP 2.5: Drop Semantic View and Intelligence Agent
-- ============================================================================
-- Remove agent from Snowflake Intelligence object first
ALTER SNOWFLAKE INTELLIGENCE IF EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
DROP AGENT SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.LABELME_CATALOG_AGENT;

-- Drop Intelligence Agent
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.LABELME_CATALOG_AGENT;

-- Drop Semantic View (in shared SEMANTIC_MODELS schema)
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG;

-- Drop supporting views
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_BASE;
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.V_LABELME_CATALOG_AGGREGATED;

-- Note: We don't drop the Intelligence object itself as it may contain other agents
-- If you need to remove it: DROP SNOWFLAKE INTELLIGENCE IF EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

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

