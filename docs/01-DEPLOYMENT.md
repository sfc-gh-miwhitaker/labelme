# Deployment Guide - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16

## Prerequisites

- Snowflake account with ACCOUNTADMIN access
- Web browser (Chrome, Firefox, Safari, Edge)
- ~15 minutes for deployment

## Deployment Steps

### Step 1: Open Snowsight

1. Navigate to [app.snowflake.com](https://app.snowflake.com)
2. Log in with your credentials
3. Verify you have ACCOUNTADMIN role access

### Step 2: Create New Worksheet

1. Click **+ Worksheet** in the left sidebar
2. Name it "LabelMe Demo Deployment"

### Step 3: Deploy the Demo

1. Open `deploy_all.sql` from this repository
2. **Copy the entire script** (Ctrl+A, Ctrl+C)
3. **Paste into the worksheet** (Ctrl+V)
4. Click **Run All** (or Ctrl+Shift+Enter)

### Step 4: Wait for Completion

The deployment takes approximately 10 minutes:

| Phase | Duration | What's Happening |
|-------|----------|------------------|
| Setup | ~1 min | Creating warehouse, schemas |
| Data Load | ~3 min | Generating 57,000 synthetic records |
| AI Processing | ~5 min | Running Cortex AI on dirty data |
| Views/DMFs | ~1 min | Creating analytics views and metrics |

### Step 5: Verify Deployment

After completion, run these verification queries:

```sql
-- Check tables were created
SELECT table_name, row_count 
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'LABELME';

-- Check data quality score
SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.V_DATA_QUALITY_SCORECARD;

-- View sample cleaned data
SELECT artist_name, country_code, quality_score
FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS
LIMIT 10;
```

### Step 6: Access Streamlit Dashboard

1. In Snowsight, click **Streamlit** in the left sidebar
2. Find **LABELME_DASHBOARD**
3. Click to open the data quality monitoring dashboard

## Troubleshooting

### "Insufficient privileges" error
- Ensure you're using ACCOUNTADMIN role
- Run: `USE ROLE ACCOUNTADMIN;`

### "CORTEX functions not available" error
- Verify your account has Cortex enabled
- Check region availability at [Snowflake Cortex Availability](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions#availability)

### "Warehouse does not exist" error
- The script creates the warehouse; re-run from the beginning
- Or manually create: `CREATE WAREHOUSE SFE_LABELME_WH WITH WAREHOUSE_SIZE='XSMALL';`

### Script times out
- Increase session timeout in account settings
- Or run script sections individually (setup → data → transformations → views)

## What Gets Created

See the [README](../README.md) for a complete list of created objects.

## Next Steps

After deployment:
1. Explore the Streamlit dashboard
2. Review [Usage Guide](02-USAGE.md) for demo walkthrough
3. When done, follow [Cleanup Guide](03-CLEANUP.md) to remove all objects

