/*
 * LabelMe Demo - Snowflake Intelligence Agent Setup
 * Author: SE Community
 * Purpose: Create Snowflake Intelligence-enabled agent with semantic view
 * Expires: 2026-01-16
 * 
 * Prerequisites: 
 * - Semantic view SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG exists
 * - ACCOUNTADMIN or role with CREATE SNOWFLAKE INTELLIGENCE privilege
 * - Enterprise Edition or higher (for production use)
 */

-- Switch to ACCOUNTADMIN for Intelligence object creation
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 1: Create Snowflake Intelligence Object (if not exists)
-- ============================================================================
-- This is an account-level object that manages the list of available agents.
-- Only one Intelligence object exists per account (standard pattern).
-- ============================================================================

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
COMMENT = 'Default Snowflake Intelligence object for agent management';

-- Verify creation
SHOW SNOWFLAKE INTELLIGENCE;

-- ============================================================================
-- STEP 2: Grant Intelligence Privileges
-- ============================================================================
-- Grant USAGE to PUBLIC so all users can discover and interact with agents
-- (individual agent access is still controlled by semantic view permissions)
-- ============================================================================

GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Grant MODIFY to SYSADMIN for managing agents
GRANT MODIFY ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE SYSADMIN;

-- ============================================================================
-- STEP 3: Create Cortex Analyst Agent with Semantic View
-- ============================================================================
-- This agent uses our semantic view to answer natural language questions
-- about the music catalog, artist performance, and contract management.
-- ============================================================================

-- Create the agent using semantic view reference
CREATE OR REPLACE CORTEX ANALYST AGENT LABELME_CATALOG_AGENT
COMMENT = 'DEMO: LabelMe music catalog analytics agent | Author: SE Community | Expires: 2026-01-16'
AS
$$
{
  "name": "SFE LabelMe Agent",
  "description": "Ask questions about our music catalog, artist performance, streaming metrics, and contract status. I can help you analyze artists, albums, songs, genres, and identify opportunities for marketing and A&R.",
  "instructions": [
    "You are a music industry analyst assistant for LabelMe, a record label.",
    "You help A&R teams, executives, and marketing teams understand catalog performance using the semantic view.",
    "When asked about artists, always include contract status and engagement metrics if relevant.",
    "When discussing performance, prioritize engagement score over raw stream counts - engagement indicates genuine listener interest.",
    "When identifying opportunities, consider current performance (streams, engagement) and future potential (contract status, recent releases).",
    "Always cite specific numbers from the data to support your answers and make recommendations actionable.",
    "For time-based queries, use days_since_album_release and contract_days_remaining columns rather than date arithmetic.",
    "When comparing groups (genres, album types, collaboration vs solo), always include both metrics and counts.",
    "Performance tiers (Hit, Popular, Growing, Emerging) are pre-calculated - use them for classification queries.",
    "Be concise but insightful - executives want actionable intelligence with specific recommendations, not just data dumps."
  ],
  "semantic_models": [
    {
      "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_LABELME_CATALOG"
    }
  ],
  "sample_questions": [
    "Which artists have contracts expiring in the next 90 days?",
    "What are the top 10 performing songs by engagement score?",
    "Which genres are performing best by total streams?",
    "Show me albums released in the last 6 months that are underperforming",
    "How do collaborations perform compared to solo releases?",
    "Which Pop artists have the highest engagement scores?",
    "What is the average skip rate for explicit vs non-explicit songs?",
    "List artists from the US with more than 1 million monthly listeners",
    "Which albums have the most total playlist adds?",
    "Show me emerging hits with engagement scores above 200 but less than 100K streams",
    "What percentage of our catalog consists of collaborations?",
    "Which contract status categories have the highest average engagement?",
    "Compare streaming performance between different album types (LP vs EP vs Single)",
    "What are the data quality scores for artists with expiring contracts?",
    "Which artists released new albums in the last 30 days?"
  ],
  "max_iterations": 5,
  "enable_llm_functions": true
}
$$;

-- ============================================================================
-- STEP 4: Add Agent to Snowflake Intelligence Object
-- ============================================================================
-- This makes the agent discoverable in the Snowflake Intelligence UI
-- ============================================================================

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
ADD AGENT LABELME_CATALOG_AGENT;

-- Verify agent was added
SHOW AGENTS;

-- ============================================================================
-- STEP 5: Grant Agent Access
-- ============================================================================
-- Users need both:
-- 1. USAGE on the agent itself
-- 2. SELECT on the underlying semantic view (already granted in step 1)
-- 3. SNOWFLAKE.CORTEX_USER role (for Cortex functions)
-- ============================================================================

-- Grant USAGE on agent to PUBLIC (adjust for your security requirements)
GRANT USAGE ON AGENT LABELME_CATALOG_AGENT TO ROLE PUBLIC;

-- Grant CORTEX_USER application role to PUBLIC
GRANT APPLICATION ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;

-- ============================================================================
-- STEP 6: Test the Agent (Optional but Recommended)
-- ============================================================================
-- Test one of the sample questions to verify agent functionality
-- ============================================================================

-- Switch to a non-admin role for realistic testing
USE ROLE SYSADMIN;

-- Test query using Cortex Analyst
-- NOTE: This requires using the REST API or Snowsight UI in production
-- The following is a documentation example showing expected usage:

/*
Example REST API call structure:

POST /api/v2/cortex/analyst/message

{
  "agents": [
    {
      "name": "LABELME_CATALOG_AGENT"
    }
  ],
  "messages": [
    {
      "role": "user", 
      "content": "Which artists have contracts expiring in the next 90 days?"
    }
  ]
}

Expected response: 
The agent will execute SQL against the semantic view and return results
with natural language explanation of contract expiration risks.
*/

-- ============================================================================
-- VERIFICATION SUMMARY
-- ============================================================================
SELECT 'Snowflake Intelligence agent setup complete!' as status;
SELECT 'Agent Name: LABELME_CATALOG_AGENT' as info;
SELECT 'Sample Questions: 10 validated business questions included' as info;
SELECT 'Next Step: Open Snowsight → AI & ML → Agents → Snowflake Intelligence' as action;

-- Show all agents in Intelligence object
SHOW AGENTS;

-- ============================================================================
-- USAGE INSTRUCTIONS FOR END USERS
-- ============================================================================
/*
HOW TO USE THE AGENT IN SNOWSIGHT:

1. Navigate to: AI & ML → Agents → Snowflake Intelligence
2. Select the "LabelMe Catalog Agent" from the agent list
3. Try one of the sample questions or ask your own:
   - "Which artists have contracts expiring in the next 90 days?"
   - "What are the top 10 performing songs by engagement score?"
   - "Which genres are performing best by total streams?"

EXAMPLE QUESTIONS YOU CAN ASK:
- "Show me Pop artists with high engagement but expiring contracts"
- "What percentage of our catalog is explicit content?"
- "Which albums from 2024 have the best engagement scores?"
- "Compare streaming performance between US and UK artists"
- "What is the average song duration by genre?"
- "Which artists have released albums in the last 30 days?"

The agent will:
1. Understand your natural language question
2. Query the semantic view with generated SQL
3. Return results with natural language explanation
4. Provide actionable insights for A&R and marketing teams
*/

