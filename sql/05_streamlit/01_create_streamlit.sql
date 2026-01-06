/*
 * LabelMe Demo - Streamlit Dashboard Creation
 * Author: SE Community
 * Purpose: Create the Streamlit data quality dashboard
 * Expires: 2026-01-16
 * 
 * Prerequisites: 
 * - Git repository stage exists
 * - Warehouse exists
 */

USE ROLE ACCOUNTADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

-- Create Streamlit app from Git repository
CREATE OR REPLACE STREAMLIT LABELME_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.LABELME_GIT_REPOS.sfe_labelme_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_LABELME_WH
    TITLE = 'SFE LabelMe Dashboard'
    COMMENT = 'DEMO: LabelMe Data Quality Dashboard | Author: SE Community | Expires: 2026-01-16';

-- Grant access to PUBLIC role for demo accessibility
GRANT USAGE ON STREAMLIT LABELME_DASHBOARD TO ROLE PUBLIC;

-- Verify creation
SHOW STREAMLITS IN SCHEMA SNOWFLAKE_EXAMPLE.LABELME;

/*
 * To access the dashboard:
 * 1. In Snowsight, click "Streamlit" in the left sidebar
 * 2. Find "LABELME_DASHBOARD" in the list
 * 3. Click to open
 * 
 * Or use the direct URL format:
 * https://<account>.snowflakecomputing.com/#/streamlit-apps/SNOWFLAKE_EXAMPLE.LABELME.LABELME_DASHBOARD
 */

