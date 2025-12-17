/*
 * LabelMe Demo - Stream Creation
 * Author: SE Community
 * Purpose: Create CDC streams for incremental processing
 * Expires: 2026-01-16
 * 
 * Prerequisites: RAW tables exist
 */

USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- Create streams for change data capture
CREATE OR REPLACE STREAM ARTISTS_STREAM 
    ON TABLE RAW_ARTISTS
    COMMENT = 'DEMO: CDC stream for artists | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM ALBUMS_STREAM 
    ON TABLE RAW_ALBUMS
    COMMENT = 'DEMO: CDC stream for albums | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM SONGS_STREAM 
    ON TABLE RAW_SONGS
    COMMENT = 'DEMO: CDC stream for songs | Author: SE Community | Expires: 2026-01-16';

CREATE OR REPLACE STREAM METRICS_STREAM 
    ON TABLE RAW_STREAMING_METRICS
    COMMENT = 'DEMO: CDC stream for metrics | Author: SE Community | Expires: 2026-01-16';

-- Verify creation
SHOW STREAMS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

