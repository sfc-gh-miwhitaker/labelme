# Dynamic Tables Migration Guide

**Status:** Optional Modernization  
**Priority:** Medium  
**Risk:** Low  
**Effort:** 2-4 hours (including validation)

---

## Overview

This demo includes an **optional modernization path** from the traditional Streams + Tasks pattern to the modern **Dynamic Tables** approach.

**Current Pattern (Traditional):**
- ✅ 4 Streams tracking changes to RAW tables
- ✅ 1 Stored Procedure with cleaning logic
- ✅ 1 Scheduled Task running daily

**Modern Alternative (Dynamic Tables):**
- ✅ 4 Dynamic Tables with declarative SQL
- ✅ Automatic refresh scheduling by Snowflake
- ✅ 60% code reduction

---

## Why Consider Dynamic Tables?

### Benefits

| Benefit | Description |
|---------|-------------|
| **Code Simplification** | Eliminate 80+ lines of boilerplate (streams, procedures, tasks) |
| **Declarative SQL** | Specify WHAT you want, not HOW to get it |
| **Automatic Optimization** | Snowflake manages refresh scheduling |
| **Better Observability** | Built-in monitoring via `DYNAMIC_TABLE_REFRESH_HISTORY()` |
| **Easier Maintenance** | Single object per transformation instead of 3 |

### Trade-offs

| Consideration | Impact |
|---------------|--------|
| **Cost** | Similar (may be slightly lower with auto-optimization) |
| **Flexibility** | Slightly less control over exact refresh timing |
| **Familiarity** | Team needs to learn new pattern |

---

## Current Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ RAW_ARTISTS │────▶│ ARTISTS_    │────▶│ CLEAN_DATA_ │────▶│ STG_ARTISTS │
│             │     │ STREAM      │     │ TASK        │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │ CLEAN_DATA_WITH_    │
                                    │ CORTEX (Procedure)  │
                                    └─────────────────────┘
```

**Objects Required:** 3 per entity (Stream + Task + Procedure)  
**Refresh Logic:** Imperative (manual scheduling)  
**Maintenance:** Higher (update procedure, manage task schedules)

---

## Dynamic Tables Architecture

```
┌─────────────┐                         ┌─────────────────┐
│ RAW_ARTISTS │────────────────────────▶│ STG_ARTISTS_DT  │
│             │   (Automatic refresh    │ (Dynamic Table) │
└─────────────┘    managed by SF)       └─────────────────┘
```

**Objects Required:** 1 per entity (Dynamic Table)  
**Refresh Logic:** Declarative (TARGET_LAG = '1 HOUR')  
**Maintenance:** Lower (update query, Snowflake handles rest)

---

## Migration Options

### Option A: Side-by-Side Validation (Recommended)

**Timeline:** 2-4 weeks

1. **Deploy Dynamic Tables** (Day 1)
   - Run `sql/03_transformations/05_create_dynamic_tables.sql`
   - Creates `STG_ARTISTS_DT`, `STG_ALBUMS_DT`, etc.
   - Old pattern continues running

2. **Validate Data** (Week 1-2)
   ```sql
   -- Compare row counts
   SELECT 'Old' as source, COUNT(*) FROM STG_ARTISTS
   UNION ALL
   SELECT 'New', COUNT(*) FROM STG_ARTISTS_DT;
   
   -- Spot check sample data
   SELECT * FROM STG_ARTISTS ORDER BY artist_id LIMIT 10;
   SELECT * FROM STG_ARTISTS_DT ORDER BY artist_id LIMIT 10;
   ```

3. **Disable Old Task** (Week 2)
   ```sql
   ALTER TASK CLEAN_DATA_TASK SUSPEND;
   ```

4. **Monitor Dynamic Tables** (Week 3-4)
   ```sql
   -- Check refresh status
   SELECT * FROM TABLE(
       INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
           'SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS_DT'
       )
   ) ORDER BY data_timestamp DESC;
   ```

5. **Clean Up Old Pattern** (Week 4)
   ```sql
   -- Drop streams, procedure, task
   DROP STREAM ARTISTS_STREAM;
   DROP PROCEDURE CLEAN_DATA_WITH_CORTEX();
   DROP TASK CLEAN_DATA_TASK;
   
   -- Rename Dynamic Tables to replace old tables
   ALTER DYNAMIC TABLE STG_ARTISTS_DT RENAME TO STG_ARTISTS;
   ```

### Option B: Direct Replacement (Higher Risk)

**Timeline:** 1 day

```sql
-- 1. Drop old pattern
DROP TASK CLEAN_DATA_TASK;
DROP PROCEDURE CLEAN_DATA_WITH_CORTEX();
DROP STREAM ARTISTS_STREAM;
DROP STREAM ALBUMS_STREAM;
DROP STREAM SONGS_STREAM;
DROP STREAM METRICS_STREAM;
DROP TABLE STG_ARTISTS;
DROP TABLE STG_ALBUMS;
DROP TABLE STG_SONGS;
DROP TABLE STG_STREAMING_METRICS;

-- 2. Deploy Dynamic Tables
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/05_create_dynamic_tables.sql;

-- 3. Rename Dynamic Tables
ALTER DYNAMIC TABLE STG_ARTISTS_DT RENAME TO STG_ARTISTS;
ALTER DYNAMIC TABLE STG_ALBUMS_DT RENAME TO STG_ALBUMS;
ALTER DYNAMIC TABLE STG_SONGS_DT RENAME TO STG_SONGS;
ALTER DYNAMIC TABLE STG_STREAMING_METRICS_DT RENAME TO STG_STREAMING_METRICS;
```

---

## Deployment Instructions

### Using deploy_all.sql

The Dynamic Tables script is included but commented out:

```sql
-- UNCOMMENT THE LINE BELOW to use Dynamic Tables
-- EXECUTE IMMEDIATE FROM @.../05_create_dynamic_tables.sql;
```

**To Enable:**
1. Edit `deploy_all.sql`
2. Uncomment the Dynamic Tables line
3. Re-run deployment

### Manual Deployment

```sql
-- Execute the Dynamic Tables script directly
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/sql/03_transformations/05_create_dynamic_tables.sql;
```

---

## Monitoring Dynamic Tables

### Check Refresh Status

```sql
-- List all Dynamic Tables
SHOW DYNAMIC TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- Check specific table refresh history
SELECT 
    name,
    refresh_mode,
    target_lag,
    data_timestamp,
    scheduling_state,
    last_suspended_on
FROM TABLE(
    INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
        'SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS_DT'
    )
)
ORDER BY data_timestamp DESC
LIMIT 10;
```

### Monitor Refresh Duration

```sql
-- Check how long refreshes take
SELECT 
    name,
    refresh_start_time,
    refresh_end_time,
    DATEDIFF('second', refresh_start_time, refresh_end_time) as duration_seconds,
    state
FROM TABLE(
    INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
        'SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS_DT'
    )
)
WHERE state = 'SUCCEEDED'
ORDER BY refresh_start_time DESC
LIMIT 10;
```

### Check Data Freshness

```sql
-- How fresh is the data?
SELECT 
    name,
    target_lag,
    data_timestamp,
    DATEDIFF('minute', data_timestamp, CURRENT_TIMESTAMP()) as minutes_behind
FROM INFORMATION_SCHEMA.DYNAMIC_TABLES
WHERE table_schema = 'LABELME';
```

---

## Cost Comparison

| Pattern | Components | Typical Cost |
|---------|-----------|--------------|
| **Streams + Tasks** | 4 streams + 1 task + 1 warehouse | ~$3-5/month |
| **Dynamic Tables** | 4 dynamic tables + 1 warehouse | ~$3-5/month |

**Cost is similar** because:
- Both use same warehouse (SFE_LABELME_WH)
- Both process same data volume
- Dynamic Tables may be slightly more efficient with automatic scheduling

---

## Rollback Plan

If you encounter issues with Dynamic Tables:

```sql
-- 1. Suspend Dynamic Tables
ALTER DYNAMIC TABLE STG_ARTISTS_DT SUSPEND;
ALTER DYNAMIC TABLE STG_ALBUMS_DT SUSPEND;
ALTER DYNAMIC TABLE STG_SONGS_DT SUSPEND;
ALTER DYNAMIC TABLE STG_STREAMING_METRICS_DT SUSPEND;

-- 2. Resume old task
ALTER TASK CLEAN_DATA_TASK RESUME;

-- 3. Wait for task to run and repopulate STG tables

-- 4. Drop Dynamic Tables if desired
DROP DYNAMIC TABLE STG_ARTISTS_DT;
DROP DYNAMIC TABLE STG_ALBUMS_DT;
DROP DYNAMIC TABLE STG_SONGS_DT;
DROP DYNAMIC TABLE STG_STREAMING_METRICS_DT;
```

---

## FAQ

### Q: Will this break my existing views and Streamlit app?

**A:** No, if you follow Option A (side-by-side). The old STG tables continue to exist until you rename the Dynamic Tables.

### Q: Can I customize the refresh frequency?

**A:** Yes! Change `TARGET_LAG = '1 HOUR'` to any value:
- `'15 MINUTES'` for near-real-time
- `'1 DAY'` for daily batch processing
- `'DOWNSTREAM'` to refresh only when dependent tables need it

### Q: What if I need custom logic that doesn't fit in a SELECT statement?

**A:** Stick with the Streams + Tasks pattern. Dynamic Tables work best for transformations that can be expressed as declarative SQL.

### Q: Does this work with the Semantic View?

**A:** Yes! The Semantic View queries the STG tables, which can be either regular tables (current) or Dynamic Tables (new). No changes needed.

### Q: What about the Cortex Agent?

**A:** No impact. The agent queries the Semantic View, which queries the STG tables. The underlying implementation doesn't matter.

---

## Decision Matrix

| Use Case | Recommendation |
|----------|---------------|
| **Demo/POC** | Either pattern works |
| **Learning Snowflake** | Start with Streams + Tasks (more explicit) |
| **Production pipeline** | Consider Dynamic Tables (less maintenance) |
| **Complex orchestration** | Streams + Tasks (more control) |
| **Simple transformations** | Dynamic Tables (less code) |
| **Team familiar with Tasks** | Streams + Tasks (lower learning curve) |
| **Team new to Snowflake** | Dynamic Tables (simpler mental model) |

---

## Next Steps

1. **Read the migration script:** `sql/03_transformations/05_create_dynamic_tables.sql`
2. **Choose your migration path:** Side-by-side (safe) or Direct (fast)
3. **Test in dev first:** Validate the pattern works for your use case
4. **Deploy to production:** Follow the chosen migration steps

---

## References

- [Snowflake Docs: Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)
- [Best Practices for Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-best-practices)
- [Dynamic Tables vs Streams and Tasks](https://docs.snowflake.com/en/user-guide/dynamic-tables-comparison)

---

**Questions?** See the [updatetheworld audit report](.cursor/UPDATETHEWORLD_AUDIT_2026-01-06.md) for detailed analysis.

