# Usage Guide - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16

## Demo Walkthrough

This guide walks you through demonstrating the AI-powered data quality pipeline.

### Part 1: Show the Problem (Dirty Data)

Open a Snowsight worksheet and run:

```sql
-- Show sample dirty artist data
SELECT 
    artist_id,
    artist_name,
    country_of_origin,
    genre_primary
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS
WHERE artist_name LIKE '%swift%' 
   OR artist_name LIKE '%TAYLOR%'
   OR artist_name LIKE '%Bettles%'
LIMIT 10;

-- Show variety of data quality issues
SELECT 
    artist_name,
    CASE 
        WHEN artist_name != INITCAP(artist_name) THEN 'Capitalization'
        WHEN country_of_origin IN ('USA', 'United States', 'U.S.A.') THEN 'Standardization'
        ELSE 'Spelling'
    END as issue_type
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS
LIMIT 20;
```

### Part 2: Show AI Cleaning in Action

Demonstrate Cortex functions directly:

```sql
-- Fix spelling with CORTEX.COMPLETE
SELECT 
    'Bettles' as dirty_name,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'Correct the spelling of this music artist name. Return ONLY the corrected name, nothing else: Bettles'
    ) as cleaned_name;

-- Fix capitalization
SELECT 
    'TAYLOR swift' as dirty_name,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'Fix the capitalization of this music artist name. Return ONLY the properly capitalized name: TAYLOR swift'
    ) as cleaned_name;

-- Translate non-English
SELECT 
    '君の名は' as japanese_title,
    SNOWFLAKE.CORTEX.TRANSLATE('君の名は', 'ja', 'en') as english_title;
```

### Part 3: Compare Before and After

Show the transformation:

```sql
-- Side-by-side comparison
SELECT 
    r.artist_id,
    r.artist_name as raw_name,
    s.artist_name as cleaned_name,
    r.country_of_origin as raw_country,
    s.country_code as std_country,
    s.quality_score
FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS r
JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS s ON r.artist_id = s.artist_id
WHERE r.artist_name != s.artist_name
LIMIT 10;
```

### Part 4: Review Data Quality Metrics

```sql
-- Overall quality scorecard
SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.V_DATA_QUALITY_SCORECARD;

-- Quality trends (if multiple runs)
SELECT 
    metric_name,
    metric_value,
    measured_at
FROM SNOWFLAKE_EXAMPLE.LABELME.DMF_HISTORY
ORDER BY measured_at DESC
LIMIT 20;
```

### Part 5: Explore the Streamlit Dashboard

1. Open Streamlit from the Snowsight sidebar
2. Launch **LABELME_DASHBOARD**
3. Walk through each tab:
   - **Quality Overview**: Overall scores and trends
   - **Artist Analytics**: Top artists by streams
   - **Streaming Insights**: Platform comparison
   - **Pipeline Monitor**: Processing status
   - **Before/After**: Visual data comparison

### Part 6: Demonstrate Incremental Processing

Show how the pipeline handles new data:

```sql
-- Insert new dirty data
INSERT INTO SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS 
(artist_id, artist_name, country_of_origin, genre_primary, label_signed_date, contract_end_date)
VALUES
(9001, 'ADELL', 'United Kingdom', 'POP', '2020-01-15', '2025-12-31'),
(9002, 'ed SHEERAN', 'UK', 'pop music', '2019-06-01', '2026-06-30');

-- Check the stream
SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.ARTISTS_STREAM;

-- Manually trigger the task (or wait for daily schedule)
EXECUTE TASK SNOWFLAKE_EXAMPLE.LABELME.CLEAN_DATA_TASK;

-- Verify cleaning
SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS
WHERE artist_id IN (9001, 9002);
```

## Key Talking Points

### Why Cortex AI?

1. **No Data Movement**: Data stays in Snowflake, no external API calls
2. **Scalability**: Process millions of records efficiently
3. **Consistency**: Automated, repeatable cleaning logic
4. **Cost-Effective**: Pay only for compute used

### Why Data Metric Functions?

1. **Automated Monitoring**: Schedule quality checks
2. **Trend Tracking**: See quality improvement over time
3. **Governance**: Document data quality for compliance
4. **Alerting**: Trigger alerts when quality drops

### Why Streams + Tasks?

1. **Incremental Processing**: Only process new/changed data
2. **Resource Efficient**: No full table scans needed
3. **Near Real-Time**: Process as data arrives
4. **Serverless Option**: No warehouse management needed

## Common Questions

**Q: How accurate is the AI cleaning?**
A: In testing, Cortex achieves >95% accuracy on spelling/capitalization. Translation accuracy depends on language pair (English pairs are most accurate).

**Q: What's the cost?**
A: Approximately $10-15/month for this demo scale. Cortex charges per token processed.

**Q: Can this handle production volumes?**
A: Yes. Cortex functions scale with your warehouse. For millions of records, use a larger warehouse.

**Q: What languages does TRANSLATE support?**
A: English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, Dutch, Polish, Russian, Swedish, Hindi.

## Next Steps

When finished with the demo, follow the [Cleanup Guide](03-CLEANUP.md) to remove all created objects.

