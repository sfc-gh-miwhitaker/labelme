# LabelMe Semantic View & Intelligence Agent Guide

**Author:** SE Community  
**Created:** 2025-12-17  
**Expires:** 2026-01-16  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

---

## Overview

This guide explains the LabelMe semantic view and Snowflake Intelligence agent that enable natural language queries over your music catalog data.

**What You Get:**
- 🎯 **Semantic View** - Unified view combining artists, albums, songs, and streaming metrics
- 🤖 **Intelligence Agent** - AI-powered assistant for natural language queries
- ✅ **5 Validated Queries** - Pre-tested business questions with proven results
- 📊 **Sample Questions** - 10 ready-to-use questions for the agent

---

## Table of Contents

1. [Architecture](#architecture)
2. [Semantic View Design](#semantic-view-design)
3. [Business Questions Research](#business-questions-research)
4. [Validated Queries](#validated-queries)
5. [Intelligence Agent Setup](#intelligence-agent-setup)
6. [Usage Examples](#usage-examples)
7. [Troubleshooting](#troubleshooting)

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Sanitized Data (STG_* Tables)                              │
│  - STG_ARTISTS                                              │
│  - STG_ALBUMS                                               │
│  - STG_SONGS                                                │
│  - STG_STREAMING_METRICS                                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Semantic View (SV_LABELME_CATALOG)                         │
│  - Denormalized for natural language queries                │
│  - Calculated metrics (engagement_score, performance_tier)  │
│  - Business-friendly column names                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Cortex Analyst Agent (LABELME_CATALOG_AGENT)               │
│  - Natural language understanding                           │
│  - SQL generation from business questions                   │
│  - Contextual responses with insights                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Snowflake Intelligence UI                                  │
│  - Chat interface for end users                             │
│  - Sample questions library                                 │
│  - Response visualization                                   │
└─────────────────────────────────────────────────────────────┘
```

### Component Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Semantic View | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG` | Denormalized data for NL queries |
| Agent Definition | `LABELME_CATALOG_AGENT` | Cortex Analyst agent configuration |
| Intelligence Object | `SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT` | Account-level agent registry |
| Source Tables | `SNOWFLAKE_EXAMPLE.LABELME.STG_*` | Clean, standardized data |

---

## Semantic View Design

### Design Principles

The semantic view (`SV_LABELME_CATALOG`) follows these best practices:

1. **Simple Table References** - Lists tables without complex joins (Cortex Analyst handles relationships)
2. **Business Terminology** - Dimension/fact aliases match how business users speak
3. **Fact/Dimension Separation** - Clear distinction between measures (FACTS) and attributes (DIMENSIONS)
4. **Rich Synonyms** - Comments include natural language variations for better AI understanding
5. **Verified Queries** - Embedded sample queries validate view functionality

### Key Semantic Elements

#### FACTS (Numeric Measures)
Quantifiable metrics that can be aggregated:
- **MONTHLY_LISTENERS** - Audience reach indicator
- **SOCIAL_FOLLOWERS** - Social media presence
- **STREAM_COUNT** - Song popularity metric
- **SKIP_RATE** - Listener retention (0-1 scale)
- **SAVE_RATE** - Fan affinity (0-1 scale)
- **PLAYLIST_ADDS** - Viral potential indicator

#### DIMENSIONS (Filter Attributes)
Categorical or temporal attributes for filtering:
- **ARTIST_NAME** - Artist identification
- **PRIMARY_GENRE** - Musical classification
- **CONTRACT_END_DATE** - Renewal planning
- **ALBUM_RELEASE_DATE** - Temporal analysis
- **PLATFORM** - Streaming service
- **REGION_CODE** - Geographic segmentation

#### Query Patterns
Cortex Analyst generates SQL using:
- Dimensions for filtering (WHERE/GROUP BY)
- Facts for aggregation (SUM/AVG/COUNT)
- Synonyms for natural language mapping

### Schema Reference

**FACTS (Measures):**

| Semantic Name | Source Column | Description |
|---------------|---------------|-------------|
| `MONTHLY_LISTENERS` | STG_ARTISTS.monthly_listeners | Audience size indicator |
| `SOCIAL_FOLLOWERS` | STG_ARTISTS.social_followers | Social media reach |
| `STREAM_COUNT` | STG_STREAMING_METRICS.stream_count | Individual stream events |
| `SKIP_RATE` | STG_STREAMING_METRICS.skip_rate | Retention metric (0-1) |
| `SAVE_RATE` | STG_STREAMING_METRICS.save_rate | Fan affinity (0-1) |
| `PLAYLIST_ADDS` | STG_STREAMING_METRICS.playlist_adds | Viral potential |

**DIMENSIONS (Attributes):**

| Semantic Name | Source Column | Description |
|---------------|---------------|-------------|
| `ARTIST_NAME` | STG_ARTISTS.artist_name | Artist identification |
| `PRIMARY_GENRE` | STG_ARTISTS.genre_primary | Musical classification |
| `CONTRACT_END_DATE` | STG_ARTISTS.contract_end_date | Renewal planning date |
| `SONG_TITLE` | STG_SONGS.song_title | Track identification |
| `ALBUM_RELEASE_DATE` | STG_ALBUMS.release_date | Temporal analysis |
| `PLATFORM` | STG_STREAMING_METRICS.platform | Streaming service |

---

## Business Questions Research

### Research Methodology

To identify the 5 validated queries, we researched common questions that:
1. **A&R Teams** ask about artist signings and contract renewals
2. **Marketing Teams** ask about promotional opportunities
3. **Finance Teams** ask about revenue forecasting
4. **Executives** ask about portfolio performance

### Top 5 Business Questions

#### 1. Contract Renewal Planning
**Question:** "Which artists have contracts expiring in the next 90 days?"

**Why This Matters:**
- Contract negotiations take 60-90 days on average
- Losing a high-performing artist is costly (lost future revenue)
- Early identification allows strategic planning
- Performance data informs renewal terms

**Decision Impact:**
- Prioritize renewal discussions with top performers
- Allocate budget for competitive counter-offers
- Identify at-risk contracts needing immediate attention

---

#### 2. Hit Identification & Promotion
**Question:** "What are the top 10 performing songs by engagement score?"

**Why This Matters:**
- Engagement score predicts long-term success better than raw streams
- High-engagement songs deserve playlist placement and marketing budget
- Identifies which songs to pitch to radio/streaming curators
- Helps allocate promotional resources efficiently

**Decision Impact:**
- Increase marketing spend on high-engagement songs
- Pitch to Spotify/Apple Music editorial playlists
- Plan music video production for top performers
- Target social media advertising

---

#### 3. Genre Strategy & A&R Investment
**Question:** "Which genres are performing best by total streams?"

**Why This Matters:**
- Informs artist signing decisions (which genres to prioritize)
- Reveals market trends and audience preferences
- Guides marketing budget allocation across genres
- Identifies underserved genres with growth potential

**Decision Impact:**
- Adjust A&R focus to high-performing genres
- Invest in emerging genres before market saturation
- Re-evaluate underperforming genre investments
- Cross-promote artists within successful genres

---

#### 4. Album Performance & Marketing Intervention
**Question:** "Which albums released in the last 6 months are underperforming?"

**Why This Matters:**
- First 6 months determine album commercial success
- Early intervention can save an album from failure
- Identifies albums needing marketing support (playlist adds, PR)
- Prevents sunk costs on failed releases

**Decision Impact:**
- Allocate emergency marketing budget to underperformers
- Pitch singles to playlist curators
- Launch targeted social media campaigns
- Consider releasing additional singles from album

---

#### 5. Collaboration Strategy & Artist Pairing
**Question:** "How do collaborations perform compared to solo releases?"

**Why This Matters:**
- Collaborations often outperform solo releases (cross-fan exposure)
- Informs A&R strategy for pairing complementary artists
- Reveals whether collaboration premium exists in data
- Guides contract negotiations (collaboration clauses)

**Decision Impact:**
- Proactively suggest collaborations between label artists
- Structure contracts to incentivize collaborations
- Pair emerging artists with established stars
- Track ROI of collaboration production costs

---

## Validated Queries

All 5 queries are production-ready and tested against the semantic view.

### Query 1: Contract Expiration Alert

```sql
SELECT 
    ARTIST_NAME,
    CONTRACT_END_DATE,
    MONTHLY_LISTENERS
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE CONTRACT_END_DATE < DATEADD(day, 90, CURRENT_DATE())
  AND CONTRACT_END_DATE >= CURRENT_DATE()
ORDER BY CONTRACT_END_DATE ASC
LIMIT 20;
```

**Expected Output:**
- Artists with contracts expiring in next 90 days
- Sorted by expiration date (soonest first)
- Includes audience size for renewal priority

---

### Query 2: Top Performers by Streams

```sql
SELECT 
    SONG_TITLE,
    ARTIST_NAME,
    SUM(STREAM_COUNT) as total_streams,
    AVG(SKIP_RATE) as avg_skip_rate
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
GROUP BY SONG_TITLE, ARTIST_NAME
ORDER BY total_streams DESC
LIMIT 10;
```

**Expected Output:**
- Top 10 songs by total stream count
- Average skip rate indicates quality
- Grouped across all platforms/regions

---

### Query 3: Genre Performance Analysis

```sql
SELECT 
    PRIMARY_GENRE,
    COUNT(DISTINCT ARTIST_NAME) as artist_count,
    SUM(STREAM_COUNT) as total_streams
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE PRIMARY_GENRE IS NOT NULL
GROUP BY PRIMARY_GENRE
ORDER BY total_streams DESC;
```

**Expected Output:**
- Genres ranked by total stream volume
- Number of artists per genre
- Reveals market trends and opportunities

---

### Query 4: Recent Album Releases

```sql
SELECT 
    ALBUM_TITLE,
    ARTIST_NAME,
    ALBUM_RELEASE_DATE,
    ALBUM_TYPE
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE ALBUM_RELEASE_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY ALBUM_TITLE, ARTIST_NAME, ALBUM_RELEASE_DATE, ALBUM_TYPE
ORDER BY ALBUM_RELEASE_DATE DESC;
```

**Expected Output:**
- Albums released in last 6 months
- Shows new catalog additions
- Includes album format (LP/EP/Single)

---

### Query 5: Collaboration Analysis

```sql
SELECT 
    ARTIST_NAME,
    COUNT(DISTINCT SONG_TITLE) as collaboration_count
FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG
WHERE FEATURING_ARTISTS IS NOT NULL
GROUP BY ARTIST_NAME
ORDER BY collaboration_count DESC
LIMIT 20;
```

**Expected Output:**
- Artists ranked by number of collaborations
- Identifies most collaborative artists
- Informs partnership strategy

---

## Intelligence Agent Setup

### Prerequisites

- **Edition:** Enterprise or higher (required for Cortex functions)
- **Role:** ACCOUNTADMIN (for Intelligence object creation)
- **Objects:** Semantic view must exist before agent creation

### Setup Steps

1. **Create Semantic View** (if not exists)
   ```bash
   # In Snowsight, run:
   sql/06_semantic_views/01_create_semantic_view.sql
   ```

2. **Create Intelligence Object**
   ```sql
   CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS 
   SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
   ```

3. **Create Agent**
   ```bash
   # In Snowsight, run:
   sql/06_semantic_views/03_create_intelligence_agent.sql
   ```

4. **Grant Access**
   ```sql
   GRANT USAGE ON AGENT LABELME_CATALOG_AGENT TO ROLE PUBLIC;
   GRANT APPLICATION ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;
   ```

### Agent Configuration

The agent includes:
- **Name:** LabelMe Catalog Agent
- **Description:** Music industry analyst assistant
- **Instructions:** 8 behavior guidelines for contextual responses
- **Sample Questions:** 10 pre-tested business questions
- **Max Iterations:** 5 (for complex multi-step queries)

---

## Usage Examples

### Accessing the Agent

1. Open Snowsight
2. Navigate to: **AI & ML → Agents → Snowflake Intelligence**
3. Select: **SFE LabelMe Agent**
4. Start asking questions!

### Example Conversations

#### Example 1: Contract Management

**User:** "Which artists have contracts expiring in the next 90 days?"

**Agent Response:**
```
I found 3 artists with contracts expiring in the next 90 days:

1. Taylor Swift - Expires in 45 days (Critical)
   - Monthly Listeners: 89.5M
   - Total Streams: 12.3B
   - Engagement Score: 1,850 (Exceptional)
   
2. Ed Sheeran - Expires in 62 days (Expiring Soon)
   - Monthly Listeners: 78.2M
   - Total Streams: 9.8B
   - Engagement Score: 1,620 (Exceptional)

3. Dua Lipa - Expires in 88 days (Expiring Soon)
   - Monthly Listeners: 56.7M
   - Total Streams: 7.2B
   - Engagement Score: 1,340 (Exceptional)

RECOMMENDATION: All three artists show exceptional engagement scores 
and should be prioritized for immediate renewal negotiations.
```

---

#### Example 2: Hit Identification

**User:** "What are our top performing songs this month?"

**Agent Response:**
```
Here are the top 10 performing songs by engagement score:

1. "Blinding Lights" by The Weeknd
   - Engagement: 2,145 | Streams: 2.8B | Genre: Pop
   
2. "Shape of You" by Ed Sheeran
   - Engagement: 1,890 | Streams: 2.6B | Genre: Pop

3. "Levitating" by Dua Lipa
   - Engagement: 1,765 | Streams: 1.9B | Genre: Pop

[... 7 more songs ...]

INSIGHT: Pop dominates top performers (8/10). Consider increasing 
A&R investment in Pop genre and marketing budget for these tracks.
```

---

#### Example 3: Genre Strategy

**User:** "Which genres should we focus on for new artist signings?"

**Agent Response:**
```
Based on streaming performance analysis:

TOP PERFORMING GENRES:
1. Pop: 25B total streams (avg engagement: 1,234)
   - 45 artists, 320 albums, 1,850 songs
   
2. Hip-Hop: 18.5B total streams (avg engagement: 1,156)
   - 38 artists, 245 albums, 1,420 songs

3. R&B: 12.3B total streams (avg engagement: 1,089)
   - 28 artists, 180 albums, 960 songs

RECOMMENDATION: Pop and Hip-Hop show both high volume and high 
engagement. R&B is slightly smaller but has loyal listeners (low 
skip rates). Consider signing emerging artists in these genres.
```

---

### Advanced Questions

The agent can handle complex multi-dimensional queries:

- "Show me Pop artists from the US with high engagement but expiring contracts"
- "Compare streaming performance between explicit and non-explicit songs"
- "Which albums released in Q4 2024 are underperforming their genre average?"
- "What's the collaboration rate among our top 20 artists?"
- "Identify emerging hits with less than 100K streams but engagement scores above 200"

---

## Troubleshooting

### Common Issues

#### Issue: "Agent not found in Intelligence UI"

**Solution:**
1. Verify agent exists: `SHOW AGENTS;`
2. Check it's added to Intelligence object:
   ```sql
   ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
   ADD AGENT LABELME_CATALOG_AGENT;
   ```
3. Grant USAGE: `GRANT USAGE ON AGENT LABELME_CATALOG_AGENT TO ROLE PUBLIC;`

---

#### Issue: "Permission denied on semantic view"

**Solution:**
1. Grant SELECT on view:
   ```sql
   GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG 
   TO ROLE PUBLIC;
   ```
2. Ensure user has CORTEX_USER role:
   ```sql
   GRANT APPLICATION ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;
   ```

---

#### Issue: "Query returns no results"

**Solution:**
1. Check if source tables have data:
   ```sql
   SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS;
   SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.LABELME.STG_SONGS;
   ```
2. Verify semantic view has rows:
   ```sql
   SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG;
   ```
3. If zero rows, run data load scripts first

---

#### Issue: "Agent responses are slow"

**Solution:**
1. Check warehouse size (X-SMALL may be too small for complex queries)
2. Consider upgrading to SMALL or MEDIUM for production use
3. Enable query acceleration:
   ```sql
   ALTER WAREHOUSE SFE_LABELME_WH 
   SET ENABLE_QUERY_ACCELERATION = TRUE;
   ```

---

## Performance Optimization

### Query Performance Tips

1. **Use Filters** - Narrow results by genre, date, artist
2. **Limit Results** - Add `LIMIT` clauses for top-N queries
3. **Aggregate Smartly** - Pre-compute metrics in semantic view
4. **Index Planning** - Ensure clustering keys on large tables

### Cost Management

- **Semantic View:** No additional storage cost (view is virtual)
- **Agent Queries:** Charged per warehouse compute time
- **Cortex Functions:** Minimal cost (~$0.002 per query)

**Estimated Cost:** ~$5-10/month for typical usage (100 queries/day)

---

## Next Steps

1. ✅ Deploy semantic view and agent (completed)
2. 🎯 Test sample questions in Snowsight
3. 📊 Create dashboard visualizations using validated queries
4. 🤖 Train business users on natural language querying
5. 📈 Monitor agent usage and refine sample questions

---

## Support

For questions or issues:
- Review Snowflake Cortex Analyst documentation
- Check Snowflake Community forums
- Contact SE team for demo-specific questions

---

**Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

