/*
 * LabelMe Demo - Schema Creation
 * Author: SE Community
 * Purpose: Create project schemas
 * Expires: 2026-01-16
 * 
 * Prerequisites: ACCOUNTADMIN role, SNOWFLAKE_EXAMPLE database exists
 */

USE ROLE ACCOUNTADMIN;

-- Create main project schema
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME
    COMMENT = 'DEMO: LabelMe Music Data Quality Pipeline | Author: SE Community | Expires: 2026-01-16';

-- Create Git repository schema
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS
    COMMENT = 'DEMO: Git repository for LabelMe project | Author: SE Community | Expires: 2026-01-16';

-- Create shared semantic models schema (if not exists)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'Shared semantic views for Cortex Analyst agents';

-- Verify creation
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'LABELME%';

