/*
 * LabelMe Demo - Table Creation
 * Author: SE Community
 * Purpose: Create RAW and STG tables for music data
 * Expires: 2026-01-16
 * 
 * Prerequisites: LABELME schema exists
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- ============================================================================
-- RAW TABLES (Dirty Source Data)
-- ============================================================================

CREATE OR REPLACE TABLE RAW_ARTISTS (
    artist_id INT NOT NULL,
    artist_name VARCHAR(500) NOT NULL COMMENT 'May contain spelling/capitalization errors',
    country_of_origin VARCHAR(100) COMMENT 'Inconsistent formats: USA, United States, US',
    genre_primary VARCHAR(100) COMMENT 'Inconsistent: rock, ROCK, Rock Music',
    genre_secondary VARCHAR(100),
    label_signed_date DATE,
    contract_end_date DATE,
    social_followers INT,
    monthly_listeners INT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_artists PRIMARY KEY (artist_id)
) COMMENT = 'DEMO: Raw artist data with quality issues | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE RAW_ALBUMS (
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    album_title VARCHAR(500) NOT NULL COMMENT 'May contain spelling/translation issues',
    release_date DATE,
    album_type VARCHAR(50) COMMENT 'Inconsistent: LP, Album, Full Length',
    genre VARCHAR(100) COMMENT 'Inconsistent formats',
    total_tracks INT,
    label_name VARCHAR(200) COMMENT 'Inconsistent: Universal, UNIVERSAL MUSIC',
    distribution_region VARCHAR(100) COMMENT 'Inconsistent region names',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_albums PRIMARY KEY (album_id),
    CONSTRAINT fk_raw_albums_artist FOREIGN KEY (artist_id) REFERENCES RAW_ARTISTS(artist_id)
) COMMENT = 'DEMO: Raw album data with quality issues | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE RAW_SONGS (
    song_id INT NOT NULL,
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    song_title VARCHAR(500) NOT NULL COMMENT 'May need translation/cleaning',
    duration_seconds INT,
    is_explicit BOOLEAN DEFAULT FALSE,
    language_original VARCHAR(50) COMMENT 'Source language code',
    featuring_artists VARCHAR(500) COMMENT 'Inconsistent: feat., ft., featuring',
    isrc_code VARCHAR(20) COMMENT 'International Standard Recording Code',
    track_number INT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_songs PRIMARY KEY (song_id),
    CONSTRAINT fk_raw_songs_album FOREIGN KEY (album_id) REFERENCES RAW_ALBUMS(album_id),
    CONSTRAINT fk_raw_songs_artist FOREIGN KEY (artist_id) REFERENCES RAW_ARTISTS(artist_id)
) COMMENT = 'DEMO: Raw song data with quality issues | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE RAW_STREAMING_METRICS (
    metric_id INT NOT NULL,
    song_id INT NOT NULL,
    platform VARCHAR(100) NOT NULL COMMENT 'Inconsistent: Spotify, SPOTIFY, spotify',
    region VARCHAR(100) NOT NULL COMMENT 'Inconsistent: US, United States, USA',
    metric_date DATE NOT NULL,
    stream_count INT DEFAULT 0,
    skip_rate DECIMAL(5,4) COMMENT 'Percentage 0.0000 to 1.0000',
    save_rate DECIMAL(5,4) COMMENT 'Percentage 0.0000 to 1.0000',
    playlist_adds INT DEFAULT 0,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_raw_metrics PRIMARY KEY (metric_id),
    CONSTRAINT fk_raw_metrics_song FOREIGN KEY (song_id) REFERENCES RAW_SONGS(song_id)
) COMMENT = 'DEMO: Raw streaming metrics with quality issues | Author: SE Community | Expires: 2026-01-16';

-- ============================================================================
-- STG TABLES (Cleaned Data)
-- ============================================================================

CREATE OR REPLACE TABLE STG_ARTISTS (
    artist_id INT NOT NULL,
    artist_name VARCHAR(500) NOT NULL COMMENT 'Cleaned and standardized',
    country_code VARCHAR(10) COMMENT 'ISO country code',
    genre_primary VARCHAR(100) COMMENT 'Standardized genre',
    genre_secondary VARCHAR(100) COMMENT 'Standardized genre',
    label_signed_date DATE,
    contract_end_date DATE,
    social_followers INT,
    monthly_listeners INT,
    quality_score DECIMAL(5,2) COMMENT 'Data quality score 0-100',
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_artists PRIMARY KEY (artist_id)
) COMMENT = 'DEMO: Cleaned artist data | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE STG_ALBUMS (
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    album_title VARCHAR(500) NOT NULL COMMENT 'Cleaned title',
    album_title_english VARCHAR(500) COMMENT 'English translation if applicable',
    release_date DATE,
    album_type VARCHAR(50) COMMENT 'Standardized: Single, EP, LP, Compilation',
    genre VARCHAR(100) COMMENT 'Standardized genre',
    total_tracks INT,
    label_name VARCHAR(200) COMMENT 'Standardized label name',
    distribution_region VARCHAR(100) COMMENT 'Standardized region',
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_albums PRIMARY KEY (album_id),
    CONSTRAINT fk_stg_albums_artist FOREIGN KEY (artist_id) REFERENCES STG_ARTISTS(artist_id)
) COMMENT = 'DEMO: Cleaned album data | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE STG_SONGS (
    song_id INT NOT NULL,
    album_id INT NOT NULL,
    artist_id INT NOT NULL,
    song_title VARCHAR(500) NOT NULL COMMENT 'Cleaned title',
    song_title_english VARCHAR(500) COMMENT 'English translation if applicable',
    duration_seconds INT,
    is_explicit BOOLEAN DEFAULT FALSE,
    language_original VARCHAR(50),
    featuring_artists VARCHAR(500) COMMENT 'Standardized format',
    isrc_code VARCHAR(20),
    track_number INT,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_songs PRIMARY KEY (song_id),
    CONSTRAINT fk_stg_songs_album FOREIGN KEY (album_id) REFERENCES STG_ALBUMS(album_id),
    CONSTRAINT fk_stg_songs_artist FOREIGN KEY (artist_id) REFERENCES STG_ARTISTS(artist_id)
) COMMENT = 'DEMO: Cleaned song data | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE TABLE STG_STREAMING_METRICS (
    metric_id INT NOT NULL,
    song_id INT NOT NULL,
    platform VARCHAR(100) NOT NULL COMMENT 'Standardized platform name',
    region_code VARCHAR(10) NOT NULL COMMENT 'ISO country code',
    metric_date DATE NOT NULL,
    stream_count INT DEFAULT 0,
    skip_rate DECIMAL(5,4),
    save_rate DECIMAL(5,4),
    playlist_adds INT DEFAULT 0,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_stg_metrics PRIMARY KEY (metric_id),
    CONSTRAINT fk_stg_metrics_song FOREIGN KEY (song_id) REFERENCES STG_SONGS(song_id)
) COMMENT = 'DEMO: Cleaned streaming metrics | Author: SE Community | Expires: 2026-01-16';

-- Verify creation
SHOW TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

