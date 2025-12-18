/*
 * LabelMe Demo - Cortex Agent Setup
 * Author: SE Community
 * Purpose: Create Cortex Agent with semantic view for natural language queries
 * Expires: 2026-01-16
 * 
 * Prerequisites: 
 * - Semantic view SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG exists
 * - Role with CREATE AGENT privilege on the schema
 */

-- ============================================================================
-- STEP 1: Create Snowflake Intelligence Object (ACCOUNTADMIN required)
-- ============================================================================
-- The Snowflake Intelligence object manages the list of agents visible in
-- the Snowflake Intelligence UI. Only one can exist per account.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
COMMENT = 'Default Snowflake Intelligence object for agent management';

-- Grant MODIFY to SYSADMIN for managing the agent list
GRANT MODIFY ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE SYSADMIN;

-- Note: Grant USAGE on this object to specific roles as needed for your security model
-- Example: GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE <your_role>;

-- ============================================================================
-- STEP 2: Create Cortex Agent with Semantic View
-- ============================================================================
-- This agent uses our semantic view to answer natural language questions
-- about the music catalog, artist performance, and contract management.
-- ============================================================================

USE ROLE SYSADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

CREATE OR REPLACE AGENT LABELME_CATALOG_AGENT
COMMENT = 'DEMO: LabelMe music catalog analytics agent | Author: SE Community | Expires: 2026-01-16'
PROFILE = '{"display_name": "LabelMe Catalog Agent", "avatar": "music-icon.png", "color": "blue"}'
FROM SPECIFICATION
$$
models:
  orchestration: claude-4-sonnet

orchestration:
  budget:
    seconds: 60
    tokens: 16000

instructions:
  system: "You are a music industry analyst assistant for LabelMe, a record label. You help A&R teams, executives, and marketing teams understand catalog performance."
  orchestration: "Use the Analyst tool to answer all questions about artists, albums, songs, and performance metrics."
  response: "When asked about artists, always include contract status and engagement metrics if relevant. When discussing performance, prioritize engagement score over raw stream counts. Always cite specific numbers from the data to support your answers. Be concise but insightful - executives want actionable intelligence with specific recommendations."
  sample_questions:
    - question: "Which artists have contracts expiring in the next 90 days?"
      answer: "I'll query the catalog to find artists with contracts expiring soon and show their performance metrics."
    - question: "What are the top 10 performing songs by engagement score?"
      answer: "I'll analyze the catalog and return the top songs ranked by engagement score."
    - question: "Which genres are performing best by total streams?"
      answer: "I'll break down streaming performance by genre to identify top performers."
    - question: "Show me albums released in the last 6 months that are underperforming"
      answer: "I'll find recent releases and identify those with below-average engagement."
    - question: "How do collaborations perform compared to solo releases?"
      answer: "I'll compare engagement metrics between collaborative and solo tracks."

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "MusicCatalogAnalyst"
      description: "Analyzes LabelMe music catalog including artists, albums, songs, streaming metrics, engagement scores, and contract status. Use this tool for all questions about catalog performance, artist performance, genre trends, contract renewals, and streaming analytics."

tool_resources:
  MusicCatalogAnalyst:
    semantic_view: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
    query_timeout_seconds: 60
$$;

-- ============================================================================
-- STEP 3: Add Agent to Snowflake Intelligence Object
-- ============================================================================
-- This makes the agent discoverable in the Snowflake Intelligence UI
-- ============================================================================

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
ADD AGENT SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.LABELME_CATALOG_AGENT;

-- ============================================================================
-- STEP 4: Grant Agent Access
-- ============================================================================
-- Grant USAGE on the agent to specific roles as needed for your security model
-- Users also need SELECT on the underlying semantic view (granted separately)
-- Example: GRANT USAGE ON AGENT LABELME_CATALOG_AGENT TO ROLE <your_role>;
-- Example: GRANT APPLICATION ROLE SNOWFLAKE.CORTEX_USER TO ROLE <your_role>;
-- ============================================================================

-- ============================================================================
-- STEP 5: Verify Setup
-- ============================================================================

SHOW AGENTS;

DESCRIBE AGENT LABELME_CATALOG_AGENT;

SHOW SNOWFLAKE INTELLIGENCES;

-- ============================================================================
-- Test the Agent
-- ============================================================================
-- To test the agent, navigate to: AI & ML → Snowflake Intelligence
-- Select "LabelMe Catalog Agent" and ask sample questions
-- ============================================================================

/*
EXAMPLE USAGE IN SNOWSIGHT:

1. Navigate to: AI & ML → Agents
2. Select "LabelMe Catalog Agent" from the agent list
3. Try sample questions:
   - "Which artists have contracts expiring in the next 90 days?"
   - "What are the top 10 performing songs by engagement score?"
   - "Which genres are performing best by total streams?"
   - "Show me Pop artists with high engagement but expiring contracts"
   - "Compare streaming performance between US and UK artists"

EXAMPLE REST API USAGE:

POST /api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/SEMANTIC_MODELS/agents/LABELME_CATALOG_AGENT:run

{
  "thread_id": "<thread-id>",
  "parent_message_id": 0,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Which artists have contracts expiring in the next 90 days?"
        }
      ]
    }
  ]
}

The agent will:
1. Understand your natural language question
2. Generate and execute SQL against the semantic view
3. Return results with natural language explanation
4. Provide actionable insights for A&R and marketing teams
*/
