"""
LabelMe Data Quality Dashboard
Author: SE Community
Purpose: Monitor music label data quality metrics
Expires: 2026-01-16

This Streamlit app provides a visual dashboard for monitoring
data quality in the LabelMe music data pipeline.
"""

from snowflake.snowpark.context import get_active_session
import streamlit as st
import pandas as pd

# Page configuration
st.set_page_config(
    page_title="LabelMe Data Quality",
    page_icon="🎵",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: 700;
        color: #1DB954;
        margin-bottom: 0.5rem;
    }
    .sub-header {
        font-size: 1rem;
        color: #666;
        margin-bottom: 2rem;
    }
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 1.5rem;
        border-radius: 10px;
        color: white;
    }
    .quality-high { color: #00C853; }
    .quality-medium { color: #FFD600; }
    .quality-low { color: #FF5252; }
    .stTabs [data-baseweb="tab-list"] {
        gap: 24px;
    }
    .stTabs [data-baseweb="tab"] {
        padding: 10px 20px;
    }
</style>
""", unsafe_allow_html=True)

# Get Snowflake session
session = get_active_session()

# Header
st.markdown('<p class="main-header">🎵 LabelMe Data Quality Dashboard</p>', unsafe_allow_html=True)
st.markdown('<p class="sub-header">AI-Powered Music Data Quality Monitoring | SE Community Demo</p>', unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.image("https://www.snowflake.com/wp-content/themes/flavor/flavor-starter/icons/snowflake-logo-color.svg", width=150)
    st.markdown("---")
    st.markdown("### 📊 Dashboard Info")
    st.markdown("""
    **Author:** SE Community  
    **Expires:** 2026-01-16  
    **Version:** 1.0.0
    """)
    st.markdown("---")
    
    # Refresh button
    if st.button("🔄 Refresh Data", use_container_width=True):
        st.cache_data.clear()
        st.rerun()

# Cache data queries
@st.cache_data(ttl=300)  # Cache for 5 minutes
def get_quality_scorecard():
    return session.sql("SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.V_DATA_QUALITY_SCORECARD").to_pandas()

@st.cache_data(ttl=300)
def get_artist_performance():
    return session.sql("""
        SELECT artist_name, country_code, genre_primary, total_streams, 
               album_count, song_count, quality_score, contract_status
        FROM SNOWFLAKE_EXAMPLE.LABELME.V_ARTIST_PERFORMANCE 
        ORDER BY total_streams DESC NULLS LAST
        LIMIT 50
    """).to_pandas()

@st.cache_data(ttl=300)
def get_streaming_trends():
    return session.sql("""
        SELECT metric_date, platform, SUM(total_streams) as streams
        FROM SNOWFLAKE_EXAMPLE.LABELME.V_STREAMING_TRENDS
        GROUP BY 1, 2
        ORDER BY metric_date
    """).to_pandas()

@st.cache_data(ttl=300)
def get_catalog_health():
    return session.sql("SELECT * FROM SNOWFLAKE_EXAMPLE.LABELME.V_CATALOG_HEALTH").to_pandas()

@st.cache_data(ttl=300)
def get_raw_vs_clean_sample():
    return session.sql("""
        SELECT 
            r.artist_id,
            r.artist_name as raw_name,
            s.artist_name as clean_name,
            r.country_of_origin as raw_country,
            s.country_code as clean_country,
            r.genre_primary as raw_genre,
            s.genre_primary as clean_genre,
            s.quality_score
        FROM SNOWFLAKE_EXAMPLE.LABELME.RAW_ARTISTS r
        JOIN SNOWFLAKE_EXAMPLE.LABELME.STG_ARTISTS s ON r.artist_id = s.artist_id
        WHERE r.artist_name != s.artist_name 
           OR r.country_of_origin != s.country_code
        LIMIT 20
    """).to_pandas()

@st.cache_data(ttl=300)
def get_contract_alerts():
    return session.sql("""
        SELECT artist_name, contract_end_date, days_until_expiry, alert_level, monthly_listeners
        FROM SNOWFLAKE_EXAMPLE.LABELME.V_CONTRACT_ALERTS
        ORDER BY days_until_expiry
        LIMIT 20
    """).to_pandas()

# Main content with tabs
tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "📈 Quality Overview", 
    "🎤 Artist Analytics", 
    "📊 Streaming Insights",
    "⚙️ Pipeline Monitor",
    "🔍 Before/After"
])

# Tab 1: Quality Overview
with tab1:
    st.markdown("### Data Quality Scorecard")
    
    try:
        quality_df = get_quality_scorecard()
        
        # Key metrics row
        col1, col2, col3, col4 = st.columns(4)
        
        artists_row = quality_df[quality_df['ENTITY'] == 'Artists'].iloc[0] if len(quality_df[quality_df['ENTITY'] == 'Artists']) > 0 else None
        songs_row = quality_df[quality_df['ENTITY'] == 'Songs'].iloc[0] if len(quality_df[quality_df['ENTITY'] == 'Songs']) > 0 else None
        metrics_row = quality_df[quality_df['ENTITY'] == 'Streaming Metrics'].iloc[0] if len(quality_df[quality_df['ENTITY'] == 'Streaming Metrics']) > 0 else None
        
        with col1:
            if artists_row is not None:
                st.metric(
                    label="👤 Artist Quality",
                    value=f"{artists_row['HIGH_QUALITY_PCT']:.1f}%",
                    delta=f"{artists_row['TOTAL_RECORDS']} records"
                )
        
        with col2:
            if songs_row is not None:
                st.metric(
                    label="🎵 Song Quality", 
                    value=f"{songs_row['HIGH_QUALITY_PCT']:.1f}%",
                    delta=f"{songs_row['TOTAL_RECORDS']} records"
                )
        
        with col3:
            if metrics_row is not None:
                st.metric(
                    label="📊 Metrics Quality",
                    value=f"{metrics_row['HIGH_QUALITY_PCT']:.1f}%",
                    delta=f"{metrics_row['TOTAL_RECORDS']} records"
                )
        
        with col4:
            total_records = quality_df['TOTAL_RECORDS'].sum() if len(quality_df) > 0 else 0
            avg_quality = quality_df['HIGH_QUALITY_PCT'].mean() if len(quality_df) > 0 else 0
            st.metric(
                label="📦 Total Records",
                value=f"{total_records:,.0f}",
                delta=f"Avg Quality: {avg_quality:.1f}%"
            )
        
        st.markdown("---")
        
        # Quality breakdown table
        st.markdown("### Quality Breakdown by Entity")
        st.dataframe(
            quality_df[['ENTITY', 'TOTAL_RECORDS', 'HIGH_QUALITY_COUNT', 'HIGH_QUALITY_PCT', 'STANDARDIZED_COUNT']],
            use_container_width=True,
            hide_index=True
        )
        
    except Exception as e:
        st.error(f"Error loading quality data: {str(e)}")
        st.info("Make sure the demo is fully deployed and tables contain data.")

# Tab 2: Artist Analytics
with tab2:
    st.markdown("### Top Artists by Streams")
    
    try:
        artists_df = get_artist_performance()
        
        if len(artists_df) > 0:
            # Top artists bar chart
            chart_data = artists_df.head(15)[['ARTIST_NAME', 'TOTAL_STREAMS']].copy()
            chart_data = chart_data.dropna()
            
            if len(chart_data) > 0:
                st.bar_chart(chart_data.set_index('ARTIST_NAME'))
            
            st.markdown("---")
            
            # Contract status breakdown
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("### Contract Status")
                contract_counts = artists_df['CONTRACT_STATUS'].value_counts()
                st.bar_chart(contract_counts)
            
            with col2:
                st.markdown("### Genre Distribution")
                genre_counts = artists_df['GENRE_PRIMARY'].value_counts().head(10)
                st.bar_chart(genre_counts)
            
            st.markdown("---")
            
            # Artist details table
            st.markdown("### Artist Details")
            st.dataframe(
                artists_df[['ARTIST_NAME', 'COUNTRY_CODE', 'GENRE_PRIMARY', 'TOTAL_STREAMS', 
                           'ALBUM_COUNT', 'SONG_COUNT', 'QUALITY_SCORE', 'CONTRACT_STATUS']],
                use_container_width=True,
                hide_index=True
            )
        else:
            st.info("No artist data available yet.")
            
    except Exception as e:
        st.error(f"Error loading artist data: {str(e)}")

# Tab 3: Streaming Insights
with tab3:
    st.markdown("### Streaming Platform Analysis")
    
    try:
        trends_df = get_streaming_trends()
        
        if len(trends_df) > 0:
            # Platform breakdown
            platform_totals = trends_df.groupby('PLATFORM')['STREAMS'].sum().sort_values(ascending=False)
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("### Streams by Platform")
                st.bar_chart(platform_totals)
            
            with col2:
                st.markdown("### Platform Market Share")
                total = platform_totals.sum()
                for platform, streams in platform_totals.items():
                    pct = (streams / total * 100) if total > 0 else 0
                    st.write(f"**{platform}:** {pct:.1f}%")
            
            st.markdown("---")
            
            # Trends over time
            st.markdown("### Streaming Trends Over Time")
            pivot_df = trends_df.pivot_table(
                index='METRIC_DATE', 
                columns='PLATFORM', 
                values='STREAMS', 
                aggfunc='sum'
            ).fillna(0)
            st.line_chart(pivot_df)
            
        else:
            st.info("No streaming data available yet.")
            
    except Exception as e:
        st.error(f"Error loading streaming data: {str(e)}")

# Tab 4: Pipeline Monitor
with tab4:
    st.markdown("### Pipeline Status")
    
    try:
        catalog_df = get_catalog_health()
        
        if len(catalog_df) > 0:
            row = catalog_df.iloc[0]
            
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("Total Artists", f"{row['TOTAL_ARTISTS']:,.0f}")
            with col2:
                st.metric("Total Albums", f"{row['TOTAL_ALBUMS']:,.0f}")
            with col3:
                st.metric("Total Songs", f"{row['TOTAL_SONGS']:,.0f}")
            with col4:
                st.metric("Languages", f"{row['LANGUAGE_COUNT']:.0f}")
            
            st.markdown("---")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("### Content Analysis")
                st.write(f"**Explicit Songs:** {row['EXPLICIT_SONGS']:,.0f} ({row['EXPLICIT_PERCENTAGE']:.1f}%)")
                st.write(f"**Non-English Songs:** {row['NON_ENGLISH_SONGS']:,.0f}")
                st.write(f"**Translated Songs:** {row['TRANSLATED_SONGS']:,.0f}")
                st.write(f"**Collaboration Songs:** {row['COLLABORATION_SONGS']:,.0f}")
            
            with col2:
                st.markdown("### Pipeline Info")
                st.write("**Schedule:** Daily at 2:00 AM PT")
                st.write("**Warehouse:** SFE_LABELME_WH (X-SMALL)")
                st.write("**Status:** Active")
                st.write(f"**Avg Duration:** {row['AVG_DURATION_SECONDS']:.0f} seconds")
        
        # Contract alerts
        st.markdown("---")
        st.markdown("### ⚠️ Contract Alerts")
        
        alerts_df = get_contract_alerts()
        if len(alerts_df) > 0:
            st.dataframe(alerts_df, use_container_width=True, hide_index=True)
        else:
            st.success("No contract alerts at this time.")
            
    except Exception as e:
        st.error(f"Error loading pipeline data: {str(e)}")

# Tab 5: Before/After
with tab5:
    st.markdown("### Data Cleaning Comparison")
    st.markdown("See how Cortex AI cleans and standardizes dirty data:")
    
    try:
        comparison_df = get_raw_vs_clean_sample()
        
        if len(comparison_df) > 0:
            # Show comparison table
            st.dataframe(
                comparison_df,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "ARTIST_ID": "ID",
                    "RAW_NAME": st.column_config.TextColumn("Raw Name", help="Original dirty data"),
                    "CLEAN_NAME": st.column_config.TextColumn("Clean Name", help="AI-cleaned data"),
                    "RAW_COUNTRY": st.column_config.TextColumn("Raw Country", help="Original format"),
                    "CLEAN_COUNTRY": st.column_config.TextColumn("ISO Code", help="Standardized"),
                    "RAW_GENRE": st.column_config.TextColumn("Raw Genre", help="Original format"),
                    "CLEAN_GENRE": st.column_config.TextColumn("Clean Genre", help="Standardized"),
                    "QUALITY_SCORE": st.column_config.ProgressColumn(
                        "Quality",
                        help="Data quality score",
                        min_value=0,
                        max_value=100,
                    ),
                }
            )
            
            st.markdown("---")
            
            # Examples of specific transformations
            st.markdown("### Transformation Examples")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("#### 🔤 Name Corrections")
                st.code("""
Before: "TAYLOR swift"  →  After: "Taylor Swift"
Before: "Bettles"       →  After: "Beatles"  
Before: "ed SHEERAN"    →  After: "Ed Sheeran"
                """)
            
            with col2:
                st.markdown("#### 🌍 Country Standardization")
                st.code("""
Before: "United States" →  After: "US"
Before: "U.K."          →  After: "GB"
Before: "canada"        →  After: "CA"
                """)
        else:
            st.info("No comparison data available. The cleaning process may not have found differences.")
            
    except Exception as e:
        st.error(f"Error loading comparison data: {str(e)}")

# Footer
st.markdown("---")
st.markdown("""
<div style="text-align: center; color: #666; font-size: 0.8rem;">
    <p>LabelMe Demo | Author: SE Community | Expires: 2026-01-16</p>
    <p>Powered by Snowflake Cortex AI & Streamlit</p>
</div>
""", unsafe_allow_html=True)

