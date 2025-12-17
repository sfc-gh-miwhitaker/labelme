# Network Flow - LabelMe Music Data Quality Demo

**Author:** SE Community  
**Last Updated:** 2025-12-17  
**Expires:** 2026-01-16 (30 days from creation)  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

> **Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview

This diagram shows the network architecture and component connectivity for the music label demo, including external connections (GitHub, users) and internal Snowflake services.

## Diagram

```mermaid
flowchart TB
    subgraph External["External"]
        USER["End Users<br/>Snowsight Browser"]
        GH["GitHub<br/>sfc-gh-miwhitaker/labelme"]
    end

    subgraph SnowflakeAccount["Snowflake Account<br/>*.snowflakecomputing.com"]
        subgraph NetworkLayer["Network Layer"]
            AUTH["Authentication<br/>OAuth / Password"]
            RBAC["Role-Based Access<br/>CORTEX_USER Role"]
        end

        subgraph Compute["Compute Layer"]
            WH["SFE_LABELME_WH<br/>X-SMALL Warehouse"]
            TASK["CLEAN_DATA_TASK<br/>Serverless Compute"]
        end

        subgraph Storage["Storage Layer<br/>SNOWFLAKE_EXAMPLE Database"]
            subgraph Schema["LABELME Schema"]
                RAW["RAW Tables"]
                STG["STG Tables"]
                VIEWS["Analytics Views"]
            end
            subgraph GitSchema["LABELME_GIT_REPOS Schema"]
                REPO["Git Repository Stage<br/>@sfe_labelme_repo"]
            end
            subgraph SemanticSchema["SEMANTIC_MODELS Schema"]
                SV["Semantic Views"]
            end
        end

        subgraph Services["AI Services"]
            CORTEX["Cortex LLM Functions<br/>COMPLETE, TRANSLATE"]
            DMF["Data Metric Functions<br/>Quality Monitoring"]
        end

        subgraph Apps["Applications"]
            STREAMLIT["Streamlit App<br/>Data Quality Dashboard"]
        end
    end

    subgraph Integration["Integrations"]
        API["SFE_LABELME_GIT_API_INTEGRATION<br/>GitHub API Access"]
    end

    USER -->|HTTPS :443| AUTH
    AUTH --> RBAC
    RBAC --> WH
    RBAC --> STREAMLIT

    GH -->|HTTPS| API
    API --> REPO
    REPO -->|EXECUTE IMMEDIATE FROM| Schema

    WH --> RAW & STG & VIEWS
    WH --> CORTEX
    TASK --> CORTEX
    CORTEX --> STG

    STG --> DMF
    DMF --> VIEWS
    VIEWS --> STREAMLIT
    SV --> STREAMLIT
```

[Edit in Mermaid Chart Playground](https://mermaidchart.com/play)

## Component Descriptions

### External Systems

| System | URL | Protocol | Purpose |
|--------|-----|----------|---------|
| **Snowsight** | `app.snowflake.com` | HTTPS :443 | User interface |
| **GitHub** | `github.com/sfc-gh-miwhitaker/labelme` | HTTPS | Source repository |

### Network Layer

| Component | Technology | Function |
|-----------|------------|----------|
| **Authentication** | OAuth 2.0 / Password | User identity verification |
| **RBAC** | Snowflake Roles | Access control (CORTEX_USER required) |

### Compute Layer

| Resource | Size | Purpose |
|----------|------|---------|
| **SFE_LABELME_WH** | X-SMALL (1 credit/hr) | Query execution, Streamlit |
| **CLEAN_DATA_TASK** | Serverless | Scheduled pipeline execution |

### Storage Layer

| Schema | Contents | Purpose |
|--------|----------|---------|
| **LABELME** | RAW_*, STG_*, Views, Streams, Tasks | Main project data |
| **LABELME_GIT_REPOS** | Git repository stage | SQL script source |
| **SEMANTIC_MODELS** | Semantic views | Cortex Analyst integration |

### AI Services

| Service | Function | Endpoint |
|---------|----------|----------|
| **Cortex COMPLETE** | Text generation/correction | `SNOWFLAKE.CORTEX.COMPLETE()` |
| **Cortex TRANSLATE** | Language translation | `SNOWFLAKE.CORTEX.TRANSLATE()` |
| **Data Metric Functions** | Quality monitoring | Custom DMFs |

### Integrations

| Integration | Type | Scope |
|-------------|------|-------|
| **SFE_LABELME_GIT_API_INTEGRATION** | API Integration | `https://github.com/sfc-gh-miwhitaker/` |

## Security Boundaries

| Boundary | Protection | Notes |
|----------|------------|-------|
| **Internet → Snowflake** | TLS 1.2+ encryption | All traffic encrypted |
| **User → Data** | Role-based access | CORTEX_USER role required for AI functions |
| **GitHub → Snowflake** | API Integration | Read-only repository access |
| **Streamlit → Data** | Session context | Inherits user's role permissions |

## Ports and Protocols

| Connection | Port | Protocol | Direction |
|------------|------|----------|-----------|
| User → Snowsight | 443 | HTTPS | Inbound |
| Snowflake → GitHub | 443 | HTTPS | Outbound |
| Internal Services | N/A | Internal | Snowflake-managed |

## Change History

See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

