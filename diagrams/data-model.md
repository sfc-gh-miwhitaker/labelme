# Data Model - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16 (30 days from creation)  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

> **Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview

This diagram shows the database schema for the music label data quality demo. The model includes RAW tables (dirty source data), STG tables (cleaned data), and their relationships. All tables live in the `SNOWFLAKE_EXAMPLE.LABELME` schema.

## Diagram

```mermaid
erDiagram
    RAW_ARTISTS ||--o{ RAW_ALBUMS : releases
    RAW_ARTISTS ||--o{ RAW_SONGS : performs
    RAW_ALBUMS ||--o{ RAW_SONGS : contains
    RAW_SONGS ||--o{ RAW_STREAMING_METRICS : tracks
    
    STG_ARTISTS ||--|| RAW_ARTISTS : "cleaned from"
    STG_ALBUMS ||--|| RAW_ALBUMS : "cleaned from"
    STG_SONGS ||--|| RAW_SONGS : "cleaned from"
    STG_STREAMING_METRICS ||--|| RAW_STREAMING_METRICS : "cleaned from"
    
    RAW_ARTISTS {
        int artist_id PK
        string artist_name "dirty: spelling, caps"
        string country_of_origin "dirty: inconsistent"
        string genre_primary "dirty: inconsistent"
        string genre_secondary
        date label_signed_date
        date contract_end_date
        int social_followers
        int monthly_listeners
    }
    
    RAW_ALBUMS {
        int album_id PK
        int artist_id FK
        string album_title "dirty: spelling, caps, translation"
        date release_date
        string album_type "dirty: LP vs Album"
        string genre "dirty: inconsistent"
        int total_tracks
        string label_name "dirty: inconsistent"
        string distribution_region "dirty: inconsistent"
    }
    
    RAW_SONGS {
        int song_id PK
        int album_id FK
        int artist_id FK
        string song_title "dirty: spelling, caps, translation"
        int duration_seconds
        boolean is_explicit
        string language_original
        string featuring_artists "dirty: feat vs ft"
        string isrc_code
        int track_number
    }
    
    RAW_STREAMING_METRICS {
        int metric_id PK
        int song_id FK
        string platform "dirty: Spotify vs SPOTIFY"
        string region "dirty: US vs United States"
        date metric_date
        int stream_count
        decimal skip_rate
        decimal save_rate
        int playlist_adds
    }
    
    STG_ARTISTS {
        int artist_id PK
        string artist_name "cleaned"
        string country_code "ISO standardized"
        string genre_primary "standardized"
        string genre_secondary "standardized"
        date label_signed_date
        date contract_end_date
        int social_followers
        int monthly_listeners
        decimal quality_score "computed"
    }
    
    STG_ALBUMS {
        int album_id PK
        int artist_id FK
        string album_title "cleaned"
        string album_title_english "translated"
        date release_date
        string album_type "standardized"
        string genre "standardized"
        int total_tracks
        string label_name "standardized"
        string distribution_region "standardized"
    }
    
    STG_SONGS {
        int song_id PK
        int album_id FK
        int artist_id FK
        string song_title "cleaned"
        string song_title_english "translated"
        int duration_seconds
        boolean is_explicit
        string language_original
        string featuring_artists "standardized"
        string isrc_code
        int track_number
    }
    
    STG_STREAMING_METRICS {
        int metric_id PK
        int song_id FK
        string platform "standardized"
        string region_code "ISO standardized"
        date metric_date
        int stream_count
        decimal skip_rate
        decimal save_rate
        int playlist_adds
    }
```

[Edit in Mermaid Chart Playground](https://mermaidchart.com/play)

## Component Descriptions

### RAW Layer (Dirty Source Data)

| Table | Purpose | Data Quality Issues |
|-------|---------|---------------------|
| **RAW_ARTISTS** | Artist master data | Spelling errors, inconsistent capitalization, varied country formats |
| **RAW_ALBUMS** | Album catalog | Title misspellings, non-English titles, inconsistent label names |
| **RAW_SONGS** | Track-level data | Multi-language titles, "feat." vs "ft." variations |
| **RAW_STREAMING_METRICS** | Platform performance | Platform name variations, region code inconsistencies |

### STG Layer (Cleaned Data)

| Table | Purpose | Cleaning Applied |
|-------|---------|------------------|
| **STG_ARTISTS** | Clean artist data | Names corrected, countries standardized to ISO codes |
| **STG_ALBUMS** | Clean album data | Titles cleaned, English translations added |
| **STG_SONGS** | Clean track data | Titles cleaned, featuring artist format standardized |
| **STG_STREAMING_METRICS** | Clean metrics | Platform/region names standardized |

### Key Relationships

- **Artists → Albums**: One artist can release many albums
- **Artists → Songs**: One artist can perform many songs (direct relationship for singles)
- **Albums → Songs**: One album contains many songs
- **Songs → Metrics**: One song has many streaming metric records (by platform/region/date)

## Change History

See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

