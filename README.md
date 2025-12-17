![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--01--16-orange)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat&logo=snowflake&logoColor=white)

# LabelMe: AI-Powered Music Data Quality Pipeline

> **DEMONSTRATION PROJECT - EXPIRES: 2026-01-16**  
> This demo uses Snowflake features current as of December 2025.  
> After expiration, this repository will be archived and made private.

**Author:** SE Community  
**Purpose:** Music label data model with AI-powered data cleansing pipeline  
**Created:** 2025-12-17 | **Expires:** 2026-01-16 (30 days) | **Status:** ACTIVE

---

## Overview

This demo showcases how a music label can use **Snowflake Cortex AI** to automatically clean and standardize dirty data from multiple sources. The pipeline handles:

- **Spelling Corrections** - Fix typos in artist/album/song names using CORTEX.COMPLETE
- **Capitalization Standardization** - Normalize "TAYLOR swift" → "Taylor Swift"
- **Language Translation** - Auto-translate non-English titles to English using CORTEX.TRANSLATE
- **Data Quality Monitoring** - Track improvements with Data Metric Functions (DMFs)
- **Automated Daily Pipeline** - Streams + Tasks for incremental processing

## First Time Here?

Follow these steps in order:

| Step | Action | Time |
|------|--------|------|
| 1 | Read `docs/01-DEPLOYMENT.md` | 2 min |
| 2 | Open Snowsight → New Worksheet | 1 min |
| 3 | Copy entire `deploy_all.sql` and paste | 1 min |
| 4 | Click **Run All** and wait | ~10 min |
| 5 | Open the Streamlit dashboard | 1 min |

**Total setup time: ~15 minutes**

---

## What Gets Created

### Database Objects (SNOWFLAKE_EXAMPLE.LABELME)

| Object Type | Name | Purpose |
|-------------|------|---------|
| **Schema** | LABELME | Main project schema |
| **Schema** | LABELME_GIT_REPOS | Git repository stage |
| **Tables** | RAW_ARTISTS, RAW_ALBUMS, RAW_SONGS, RAW_STREAMING_METRICS | Dirty source data |
| **Tables** | STG_ARTISTS, STG_ALBUMS, STG_SONGS, STG_STREAMING_METRICS | Cleaned data |
| **Streams** | ARTISTS_STREAM, ALBUMS_STREAM, SONGS_STREAM, METRICS_STREAM | CDC tracking |
| **Task** | CLEAN_DATA_TASK | Daily pipeline automation |
| **Views** | V_ARTIST_PERFORMANCE, V_CATALOG_HEALTH, V_STREAMING_TRENDS, V_DATA_QUALITY_SCORECARD | Analytics |
| **Semantic View** | SV_LABELME_CATALOG (in SEMANTIC_MODELS schema) | Natural language query interface |
| **DMFs** | DMF_NAME_CONSISTENCY, DMF_GENRE_STANDARDIZATION, DMF_TRANSLATION_COVERAGE, DMF_METADATA_COMPLETENESS | Quality metrics |
| **Streamlit** | LABELME_DASHBOARD | Data quality monitoring UI |
| **Agent** | LABELME_CATALOG_AGENT | Cortex Analyst AI assistant |

### Account-Level Objects

| Object Type | Name | Purpose |
|-------------|------|---------|
| **Warehouse** | SFE_LABELME_WH | X-SMALL compute |
| **API Integration** | SFE_LABELME_GIT_API_INTEGRATION | GitHub access |
| **Intelligence Object** | SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT | Agent registry (shared) |

---

## Architecture

### Data Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Dirty Data     │────▶│  Cortex AI      │────▶│  Clean Data     │
│  (RAW_*)        │     │  COMPLETE       │     │  (STG_*)        │
│                 │     │  TRANSLATE      │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                                               │
        ▼                                               ▼
┌─────────────────┐                           ┌─────────────────┐
│  Streams (CDC)  │                           │  DMF Quality    │
│  Track Changes  │                           │  Monitoring     │
└─────────────────┘                           └─────────────────┘
        │                                               │
        ▼                                               ▼
┌─────────────────┐                           ┌─────────────────┐
│  Daily Task     │                           │  Streamlit      │
│  Auto-Process   │                           │  Dashboard      │
└─────────────────┘                           └─────────────────┘
```

### Sample Data Issues & AI Fixes

| Issue Type | Before (Dirty) | After (Clean) |
|------------|----------------|---------------|
| Spelling | "Bettles", "Qeen" | "Beatles", "Queen" |
| Capitalization | "TAYLOR swift", "ed SHEERAN" | "Taylor Swift", "Ed Sheeran" |
| Translation | "君の名は" (Japanese) | "Your Name" |
| Standardization | "feat.", "ft.", "featuring" | "feat." |
| Country Codes | "USA", "United States", "US" | "US" |
| Platforms | "Spotify", "SPOTIFY", "spotify" | "Spotify" |

---

## Estimated Demo Costs

| Component | Size/Usage | Credits/Hour | Est. Monthly |
|-----------|------------|--------------|--------------|
| Warehouse | X-SMALL | 1 credit/hr | ~$3-5 |
| Cortex AI | ~60K records initial | ~0.5 credits | ~$2 |
| Storage | ~10MB | Minimal | <$1 |
| Tasks | Daily, ~5 min | ~0.1 credits/day | ~$3 |

**Estimated Total:** ~$10-15/month (Standard Edition)

> **Note:** Cortex functions require Enterprise Edition or higher for production use. This demo works on all editions for evaluation.

---

## Project Structure

```
labelme/
├── README.md                    # This file
├── deploy_all.sql               # Single-file deployment (copy/paste to Snowsight)
├── diagrams/                    # Architecture diagrams (Mermaid)
│   ├── data-model.md
│   ├── data-flow.md
│   ├── network-flow.md
│   └── auth-flow.md
├── docs/                        # Documentation
│   ├── 01-DEPLOYMENT.md
│   ├── 02-USAGE.md
│   └── 03-CLEANUP.md
├── sql/                         # SQL scripts (executed via Git integration)
│   ├── 01_setup/
│   ├── 02_data/
│   ├── 03_transformations/
│   ├── 04_cortex/
│   ├── 05_streamlit/
│   └── 99_cleanup/
├── streamlit/                   # Streamlit app source
│   └── streamlit_app.py
└── .github/workflows/           # Auto-archive after expiration
    └── expire-demo.yml
```

---

## Quick Links

- [Deployment Guide](docs/01-DEPLOYMENT.md)
- [Usage Guide](docs/02-USAGE.md)
- [Cleanup Guide](docs/03-CLEANUP.md)
- [Semantic View & Agent Guide](docs/04-SEMANTIC-VIEW-AND-AGENT.md) ⭐ NEW
- [Data Model Diagram](diagrams/data-model.md)
- [Data Flow Diagram](diagrams/data-flow.md)

---

## Snowflake Features Demonstrated

| Feature | Usage |
|---------|-------|
| **Cortex COMPLETE** | Text cleaning, spelling/capitalization fixes |
| **Cortex TRANSLATE** | Multi-language to English translation |
| **Cortex Analyst** | Natural language queries with AI agent |
| **Snowflake Intelligence** | Unified agent interface for end users |
| **Data Metric Functions** | Automated quality monitoring |
| **Streams** | Change data capture for incremental processing |
| **Tasks** | Scheduled daily pipeline execution |
| **Streamlit** | Interactive data quality dashboard |
| **Git Integration** | Deploy directly from GitHub repository |

---

## Legal Notice

**Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

---

## Support

For questions or issues, contact the SE team or open an issue in this repository.

