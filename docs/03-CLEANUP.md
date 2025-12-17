# Cleanup Guide - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16

## Quick Cleanup

To remove all demo objects, run the teardown script:

```sql
-- Run from Snowsight worksheet
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/99_cleanup/teardown_all.sql';
```

Or copy/paste the cleanup SQL below.

## Manual Cleanup Script

```sql
/*
 * LabelMe Demo - Complete Teardown
 * Author: SE Community
 * Purpose: Remove all demo objects
 * 
 * WARNING: This will permanently delete all demo data and objects!
 */

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- STEP 1: Suspend and drop tasks (must be done first)
-- ============================================================
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK SUSPEND;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK;

-- ============================================================
-- STEP 2: Drop Streamlit app
-- ============================================================
DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD;

-- ============================================================
-- STEP 3: Drop Data Metric Functions
-- ============================================================
DROP DATA METRIC FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.DMF_NAME_CONSISTENCY;
DROP DATA METRIC FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.DMF_GENRE_STANDARDIZATION;
DROP DATA METRIC FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.DMF_TRANSLATION_COVERAGE;
DROP DATA METRIC FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.LABELME.DMF_METADATA_COMPLETENESS;

-- ============================================================
-- STEP 4: Drop semantic views (if created)
-- ============================================================
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG;

-- ============================================================
-- STEP 5: Drop project schemas (CASCADE drops all objects within)
-- ============================================================
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.LABELME CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS CASCADE;

-- ============================================================
-- STEP 6: Drop warehouse
-- ============================================================
DROP WAREHOUSE IF EXISTS SFE_LABELME_WH;

-- ============================================================
-- STEP 7: Drop API integration (if not shared with other projects)
-- ============================================================
-- NOTE: Only drop if this integration is not used by other projects
-- DROP API INTEGRATION IF EXISTS SFE_LABELME_GIT_API_INTEGRATION;

-- ============================================================
-- VERIFICATION
-- ============================================================
-- Verify cleanup completed
SELECT 'Schemas' as object_type, COUNT(*) as remaining
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.SCHEMATA
WHERE schema_name LIKE 'LABELME%'
UNION ALL
SELECT 'Warehouse', COUNT(*)
FROM SNOWFLAKE.INFORMATION_SCHEMA.WAREHOUSES
WHERE warehouse_name = 'SFE_LABELME_WH';
```

## What Gets Removed

| Object Type | Name | Action |
|-------------|------|--------|
| Task | CLEAN_DATA_TASK | Suspended then dropped |
| Streamlit | LABELME_DASHBOARD | Dropped |
| DMFs | DMF_NAME_*, DMF_GENRE_*, DMF_TRANSLATION_*, DMF_METADATA_* | Dropped |
| Streams | *_STREAM | Dropped with schema |
| Views | V_* | Dropped with schema |
| Tables | RAW_*, STG_* | Dropped with schema |
| Schema | LABELME | Dropped CASCADE |
| Schema | LABELME_GIT_REPOS | Dropped CASCADE |
| Warehouse | SFE_LABELME_WH | Dropped |

## What's Preserved

The following objects are **NOT** removed to avoid affecting other demos:

| Object | Reason |
|--------|--------|
| SNOWFLAKE_EXAMPLE database | Shared across all SE demos |
| SEMANTIC_MODELS schema | May contain other projects' views |
| SFE_*_GIT_API_INTEGRATION | May be shared with other projects |

## Partial Cleanup Options

### Remove data only (keep structure)

```sql
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_ALBUMS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_SONGS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.RAW_STREAMING_METRICS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_ALBUMS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS;
TRUNCATE TABLE SNOWFLAKE_EXAMPLE.LABELME.STG_STREAMING_METRICS;
```

### Suspend task only (keep everything else)

```sql
ALTER TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK SUSPEND;
```

### Drop warehouse only (stop compute costs)

```sql
DROP WAREHOUSE IF EXISTS SFE_LABELME_WH;
```

## Troubleshooting

### "Object does not exist" errors
- These are safe to ignore - the object was already removed

### "Cannot drop schema with active streams"
- Suspend any tasks first, then retry

### "Insufficient privileges"
- Use ACCOUNTADMIN role: `USE ROLE ACCOUNTADMIN;`

### Verify complete cleanup

```sql
-- Should return 0 rows
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'LABELME%';
SHOW WAREHOUSES LIKE 'SFE_LABELME%';
```

