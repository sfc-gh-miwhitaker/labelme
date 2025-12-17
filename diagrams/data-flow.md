# Data Flow - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16 (30 days from creation)  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

> **Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview

This diagram shows how data flows through the music label data quality pipeline, from synthetic dirty data generation through Cortex AI cleaning to the Streamlit dashboard for quality monitoring.

## Diagram

```mermaid
flowchart TB
    subgraph Sources["Data Sources"]
        S1[("Synthetic Data<br/>GENERATOR()")]
        S2[("Multi-Language<br/>Artist Names")]
        S3[("Platform Feeds<br/>Inconsistent Format")]
    end

    subgraph Ingestion["Ingestion Layer<br/>SNOWFLAKE_EXAMPLE.LABELME"]
        RAW_A[(RAW_ARTISTS)]
        RAW_AL[(RAW_ALBUMS)]
        RAW_S[(RAW_SONGS)]
        RAW_M[(RAW_STREAMING_METRICS)]
    end

    subgraph CDC["Change Data Capture"]
        STREAM_A[[ARTISTS_STREAM]]
        STREAM_AL[[ALBUMS_STREAM]]
        STREAM_S[[SONGS_STREAM]]
        STREAM_M[[METRICS_STREAM]]
    end

    subgraph Pipeline["Daily Pipeline Task<br/>CLEAN_DATA_TASK"]
        direction TB
        CHECK{SYSTEM$STREAM_HAS_DATA?}
        CORTEX["Cortex AI Processing"]
    end

    subgraph AIProcessing["Cortex AI Functions"]
        COMPLETE["CORTEX.COMPLETE<br/>- Fix spelling<br/>- Fix capitalization<br/>- Standardize formats"]
        TRANSLATE["CORTEX.TRANSLATE<br/>- Auto-detect language<br/>- Translate to English"]
    end

    subgraph Staging["Staging Layer<br/>SNOWFLAKE_EXAMPLE.LABELME"]
        STG_A[(STG_ARTISTS)]
        STG_AL[(STG_ALBUMS)]
        STG_S[(STG_SONGS)]
        STG_M[(STG_STREAMING_METRICS)]
    end

    subgraph Quality["Data Quality Monitoring"]
        DMF1[DMF_NAME_CONSISTENCY]
        DMF2[DMF_GENRE_STANDARDIZATION]
        DMF3[DMF_TRANSLATION_COVERAGE]
        DMF4[DMF_METADATA_COMPLETENESS]
    end

    subgraph Analytics["Analytics Views"]
        V1[V_ARTIST_PERFORMANCE]
        V2[V_CATALOG_HEALTH]
        V3[V_STREAMING_TRENDS]
        V4[V_DATA_QUALITY_SCORECARD]
    end

    subgraph Consumption["Consumption Layer"]
        STREAMLIT["Streamlit Dashboard<br/>Data Quality Monitor"]
    end

    S1 --> RAW_A & RAW_AL & RAW_S & RAW_M
    S2 --> RAW_A & RAW_AL & RAW_S
    S3 --> RAW_M

    RAW_A --> STREAM_A
    RAW_AL --> STREAM_AL
    RAW_S --> STREAM_S
    RAW_M --> STREAM_M

    STREAM_A & STREAM_AL & STREAM_S & STREAM_M --> CHECK
    CHECK -->|Yes| CORTEX
    CORTEX --> COMPLETE & TRANSLATE

    COMPLETE --> STG_A & STG_AL & STG_S & STG_M
    TRANSLATE --> STG_A & STG_AL & STG_S

    STG_A & STG_AL & STG_S & STG_M --> DMF1 & DMF2 & DMF3 & DMF4
    STG_A & STG_AL & STG_S & STG_M --> V1 & V2 & V3 & V4

    DMF1 & DMF2 & DMF3 & DMF4 --> V4
    V1 & V2 & V3 & V4 --> STREAMLIT
```

[Edit in Mermaid Chart Playground](https://mermaidchart.com/play)

## Component Descriptions

### Data Sources

| Source | Technology | Output |
|--------|------------|--------|
| **Synthetic Data** | `GENERATOR(ROWCOUNT => n)` | 500 artists, 1500 albums, 5000 songs, 50000 metrics |
| **Multi-Language Names** | Random selection from language pools | Spanish, Japanese, French, German artist/song names |
| **Platform Feeds** | Simulated inconsistent formats | Varied platform names, region codes |

### Ingestion Layer

| Table | Records | Key Dirty Data Issues |
|-------|---------|----------------------|
| **RAW_ARTISTS** | 500 | Spelling, capitalization, country format |
| **RAW_ALBUMS** | 1,500 | Title spelling, non-English titles, label names |
| **RAW_SONGS** | 5,000 | Multi-language titles, featuring artist format |
| **RAW_STREAMING_METRICS** | 50,000 | Platform/region name variations |

### Change Data Capture

| Stream | Source Table | Purpose |
|--------|--------------|---------|
| **ARTISTS_STREAM** | RAW_ARTISTS | Track new/updated artists |
| **ALBUMS_STREAM** | RAW_ALBUMS | Track new/updated albums |
| **SONGS_STREAM** | RAW_SONGS | Track new/updated songs |
| **METRICS_STREAM** | RAW_STREAMING_METRICS | Track new metrics |

### Cortex AI Processing

| Function | Input | Output | Example |
|----------|-------|--------|---------|
| **CORTEX.COMPLETE** | "Bettles" | "Beatles" | Spelling correction |
| **CORTEX.COMPLETE** | "TAYLOR swift" | "Taylor Swift" | Capitalization fix |
| **CORTEX.TRANSLATE** | "君の名は" | "Your Name" | Japanese → English |

### Data Quality Monitoring

| DMF | Metric | Target |
|-----|--------|--------|
| **DMF_NAME_CONSISTENCY** | % names matching cleaned version | >95% |
| **DMF_GENRE_STANDARDIZATION** | % using standard genres | >90% |
| **DMF_TRANSLATION_COVERAGE** | % non-English translated | 100% |
| **DMF_METADATA_COMPLETENESS** | % required fields filled | >98% |

### Data Transformation Summary

| Stage | Input | Transformation | Output |
|-------|-------|----------------|--------|
| Ingest | Sources | INSERT with dirty data | RAW_* tables |
| CDC | RAW_* | Stream capture | Change records |
| Clean | Streams | Cortex AI processing | STG_* tables |
| Quality | STG_* | DMF evaluation | Metric scores |
| Analytics | STG_* | Aggregation | Views |
| Present | Views | Visualization | Dashboard |

## Change History

See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

