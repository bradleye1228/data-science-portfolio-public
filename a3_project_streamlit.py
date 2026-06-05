""" 
================================================================================================
Semester 1, 2025, COSC480 A3 Project | Intereactive Crash Data Dashboard (NZ)
================================================================================================

This program launches an interactive dashboard for analysing road crash data across New Zealand,
using crash records provided by Waka Kotahi (NZ Transport Agency). Users can explore crash trends
by filtering on year range, road speed limit, and crash severity.

The primary feature is a choropleth map that visually represents crash counts by region,
enabling spatial analysis of crash patterns. Additional visualisations include a sortable table,
bar chart, and a time-series line graph that show crash trends across selected regions and years.

Key functionality includes:

- Multi-criteria filtering (year, speed limit, severity).
- Readable and clean user interface using Streamlit.
- Regional heatmapping using Geopandas and Matplotlib.
- Interactive bar and line charts for comparative and temporal analysis.
- Ability to export filtered CSV datasets.

Author: Eduard Bradley, 13241805
Date: 01/06/2025

"""

import streamlit as st
import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
from io import BytesIO
import io
import warnings
warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=FutureWarning)

st.set_page_config(page_title="New Zealand Crash Data", layout="wide")

DATA_FILE = "data/cas_filtered.csv.gz"
SHAPEFILE_PATH = "data/regional-council-2025.shp"

NAME_MAPPING = {
    'Auckland Region': 'Auckland',
    'Bay of Plenty Region': 'Bay of Plenty Region',
    'Canterbury Region': 'Canterbury Region',
    "Hawke's Bay Region": "Hawke's Bay Region",
    'Manawatū-Whanganui Region': 'Manawatū-Whanganui Region',
    'Northland Region': 'Northland Region',
    'Taranaki Region': 'Taranaki Region',
    'Waikato Region': 'Waikato Region',
    'Wellington Region': 'Wellington Region',
    'Gisborne Region': 'Gisborne Region',
    'Marlborough Region': 'Marlborough Region',
    'Nelson Region': 'Nelson Region',
    'Otago Region': 'Otago Region',
    'Southland Region': 'Southland Region',
    'Tasman Region': 'Tasman Region',
    'West Coast Region': 'West Coast Region',
}

COLOUR_MAP = 'YlOrRd'
SPEED_CATEGORIES = list(range(10, 120, 10))


@st.cache_data
def load_csv_data():
    csv_df = pd.read_csv(
        DATA_FILE,
        usecols=['crashSeverity', 'crashYear', 'region', 'speedLimit', 'temporarySpeedLimit'],
    )
    csv_df['effective_speed'] = csv_df['temporarySpeedLimit'].fillna(csv_df['speedLimit']).astype('Int8')
    csv_df['crashYear'] = pd.to_numeric(csv_df['crashYear'])
    csv_df = csv_df.dropna(subset=['crashYear', 'effective_speed', 'region'])

    min_year = int(csv_df['crashYear'].min())
    max_year = int(csv_df['crashYear'].max())
    year_range = list(range(min_year, max_year + 1))

    csv_df['effective_speed'] = pd.Categorical(csv_df['effective_speed'], categories=SPEED_CATEGORIES, ordered=True)
    csv_df = csv_df.drop(columns=['speedLimit', 'temporarySpeedLimit'])
    csv_df['crashYear'] = pd.Categorical(csv_df['crashYear'], categories=year_range, ordered=True)
    csv_df['crashSeverity'] = pd.Categorical(csv_df['crashSeverity'])
    csv_df['region'] = pd.Categorical(csv_df['region'])

    return csv_df


@st.cache_resource
def load_geospatial_data():
    geo_df = gpd.read_file(SHAPEFILE_PATH)
    geo_df = geo_df[~geo_df['REGC2025_1'].str.contains('Area Outside Region', na=False)]
    geo_df = geo_df.to_crs(epsg=4326)
    return geo_df


@st.cache_data
def filter_crash_data(csv_df, severity_type, speed_range, year_range):
    year_as_int = csv_df['crashYear'].astype(int)
    filtered_csv_df = csv_df[
        (year_as_int >= year_range[0]) &
        (year_as_int <= year_range[1]) &
        (csv_df['effective_speed'] >= speed_range[0]) &
        (csv_df['effective_speed'] <= speed_range[1])
    ]
    if severity_type and severity_type != "All Severities":
        filtered_csv_df = filtered_csv_df[filtered_csv_df['crashSeverity'] == severity_type]
    return filtered_csv_df.sort_values(by=['crashYear', 'effective_speed'])[
        ['crashYear', 'effective_speed', 'crashSeverity', 'region']
    ]


def generate_crash_counts(filtered_csv_df):
    counts_df = (
        filtered_csv_df
        .assign(REGC2025_1=filtered_csv_df['region'].astype(str).map(NAME_MAPPING))
        .groupby('REGC2025_1', observed=False)
        .size()
        .reset_index(name='crash_count')
    )
    return counts_df


def create_map_plot(merged_df, max_count):
    fig, ax = plt.subplots(figsize=(12, 12))
    merged_df.plot(
        column='crash_count', cmap=COLOUR_MAP,
        edgecolor='black', linewidth=0.5,
        legend=False, vmin=0, vmax=max_count,
        ax=ax
    )
    ax.set_axis_off()

    for region in merged_df['REGC2025_1'].values:
        region_geom = merged_df[merged_df['REGC2025_1'] == region].geometry.values[0]
        if region_geom.is_valid:
            cx = region_geom.centroid.x
            cy = region_geom.centroid.y
            region_name = region.replace(' Region', '')
            ax.text(cx, cy, region_name,
                    ha='center', va='center', fontsize=9, rotation=0,
                    bbox=dict(facecolor='white', edgecolor='none',
                              boxstyle='round,pad=0.2', alpha=0.8))

    sm = plt.cm.ScalarMappable(cmap=COLOUR_MAP, norm=plt.Normalize(vmin=0, vmax=max_count))
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax, orientation='horizontal', fraction=0.05, pad=0.04, aspect=50)
    cbar.set_label('Number of Crashes', fontsize=12)

    from matplotlib.ticker import FuncFormatter
    cbar.ax.xaxis.set_major_formatter(FuncFormatter(lambda x, p: f'{int(x):,}'))

    plt.tight_layout()
    return fig


def create_data_table(sorted_regions, total):
    fig, ax = plt.subplots(figsize=(14, 20))
    ax.axis('off')

    table_data = sorted_regions[['REGC2025_1', 'crash_count']].copy()
    table_data['REGC2025_1'] = table_data['REGC2025_1'].str.replace(' Region', '')
    table_data['crash_count'] = table_data['crash_count'].apply(lambda x: f"{x:,}")
    table = table_data.values.tolist()
    table.append(['TOTAL', f"{total:,}"])

    tbl = ax.table(
        cellText=table,
        colLabels=['REGION', 'CRASHES'],
        loc='center',
        colWidths=[0.65, 0.35],
        colColours=['#f0f0f0'] * 2,
        cellLoc='center'
    )
    tbl.auto_set_font_size(False)
    tbl.scale(1.4, 4.5)

    for (row, col), cell in tbl.get_celld().items():
        if row == 0:
            cell.set_text_props(fontweight='bold', fontsize=32)
        elif row == len(table):
            cell.set_text_props(fontweight='bold', fontsize=28)
        else:
            cell.set_text_props(fontsize=28)

    return fig


def create_bar_chart(sorted_regions, selected_regions=None, year_range=None, speed_range=None, severity=None):
    if not selected_regions:
        st.warning("Please select at least one region to display on the barchart.")
        return None

    filtered_selected_regions = sorted_regions[sorted_regions['REGC2025_1'].isin(selected_regions)]
    filtered_selected_regions = filtered_selected_regions.sort_values(by='crash_count', ascending=False)

    fig, ax = plt.subplots(figsize=(14, 10))
    regions = filtered_selected_regions['REGC2025_1'].str.replace(' Region', '')
    crash_counts = filtered_selected_regions['crash_count']

    ax.barh(regions, crash_counts, edgecolor='black')
    ax.set_xlabel('Number of Crashes', fontsize=14)
    ax.set_ylabel('Region', fontsize=14)
    title = f"New Zealand Crash Counts ({year_range[0]}–{year_range[1]}) | Speed: {speed_range[0]}–{speed_range[1]} km/h"
    if severity and severity != "All Severities":
        title += f" | Severity: {severity}"
    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.invert_yaxis()

    plt.tight_layout()
    plt.grid(True)
    return fig


def create_line_chart_matplotlib(filtered_df, selected_regions, year_range, speed_range=None, severity=None):
    if not selected_regions:
        st.warning("Please select at least one region to display on the line graph.")
        return None

    selected_years = list(range(year_range[0], year_range[1] + 1))
    region_df = filtered_df[filtered_df['region'].isin(selected_regions)]

    grouped = (
        region_df
        .groupby(['crashYear', 'region'], observed=False)
        .size()
        .reset_index(name='crash_count')
    )

    pivot_df = grouped.pivot(index='crashYear', columns='region', values='crash_count')
    pivot_df = pivot_df.reindex(selected_years).fillna(0)
    pivot_df = pivot_df[selected_regions]

    fig, ax = plt.subplots(figsize=(14, 6))
    for region in pivot_df.columns:
        ax.plot(pivot_df.index, pivot_df[region], marker='x', label=region)

    title = f"Yearly Crash Trends ({year_range[0]}–{year_range[1]}) | Speed: {speed_range[0]}–{speed_range[1]} km/h"
    if severity and severity != "All Severities":
        title += f" | Severity: {severity}"
    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.set_xlabel('Year', fontsize=14)
    ax.set_ylabel('Number of Crashes', fontsize=14)
    ax.set_xlim(year_range[0], year_range[1])
    ax.set_xticks(selected_years)
    ax.tick_params(axis='x', rotation=45)
    ax.legend(title='Region', bbox_to_anchor=(1.05, 1), loc='upper left')
    ax.grid(True)
    plt.tight_layout()

    return fig


def streamlit_app():
    try:
        csv_df = load_csv_data()
        geo_df = load_geospatial_data()
    except Exception as e:
        st.error(f"Something went wrong while loading the data.\n\n**Details:** {e}")
        st.stop()

    st.title("New Zealand Road Crash Data Visualisation:")

    min_year = int(csv_df['crashYear'].min())
    max_year = int(csv_df['crashYear'].max())

    st.sidebar.header("Filter Options:")

    st.sidebar.markdown("**Year Range:**")
    year_range = st.sidebar.slider(
        "Select Year Range",
        min_value=min_year,
        max_value=max_year,
        value=(min_year, max_year),
        step=1,
        label_visibility="collapsed"
    )

    st.sidebar.markdown("**Speed Limit Range (km/h):**")
    speed_range = st.sidebar.slider(
        "Select Speed Range",
        min_value=10,
        max_value=110,
        value=(10, 110),
        step=10,
        label_visibility="collapsed"
    )

    severity_options = ["All Severities", "Non-Injury Crash", "Minor Crash", "Serious Crash", "Fatal Crash"]
    selected_severity = st.sidebar.selectbox(
        "Select Crash Severity:",
        options=severity_options,
        index=0
    )

    with st.spinner('Processing data...'):
        filtered_df = filter_crash_data(csv_df, selected_severity, speed_range, year_range)
        if filtered_df.empty:
            st.warning("No crash records match your selected filters. Please broaden your selection.")
            st.stop()

        counts_df = generate_crash_counts(filtered_df)
        merged_df = geo_df.merge(counts_df, on='REGC2025_1', how='left')
        merged_df['crash_count'] = merged_df['crash_count'].fillna(0).astype(int)

        total_crashes = merged_df['crash_count'].sum()
        max_crashes_count = merged_df['crash_count'].max() if merged_df['crash_count'].max() > 0 else 1
        sorted_regions_counts_df = merged_df.sort_values('crash_count', ascending=False)

    title_parts = [f"New Zealand Road Crashes by Region ({year_range[0]}-{year_range[1]})"]
    if selected_severity != "All Severities":
        title_parts.append(f"Severity: {selected_severity}")
    if speed_range:
        title_parts.append(f"Speed: {speed_range[0]}-{speed_range[1]} km/h")

    st.subheader(" | ".join(title_parts))

    col1, col2 = st.columns([3, 2])

    with col1:
        st.subheader("Regional Distribution:")
        map_fig = create_map_plot(merged_df, max_crashes_count)
        st.pyplot(map_fig, use_container_width=True)
        buf = BytesIO()
        map_fig.savefig(buf, format='png', bbox_inches='tight')
        st.download_button(
            label="Download Choropleth Map as PNG",
            data=buf.getvalue(),
            file_name="crash_map.png",
            mime="image/png"
        )

    with col2:
        st.subheader("Crash Counts by Region:")
        table_fig = create_data_table(sorted_regions_counts_df, total_crashes)
        st.pyplot(table_fig, use_container_width=True)
        export_table = sorted_regions_counts_df[['REGC2025_1', 'crash_count']].rename(
            columns={'REGC2025_1': 'Region', 'crash_count': 'Crash Count'}
        )
        st.download_button(
            label="Download Crash Counts Table as CSV",
            data=export_table.to_csv(index=False).encode('utf-8'),
            file_name="crash_counts_by_region.csv",
            mime="text/csv"
        )
        st.markdown(f"<h2 style='text-align: center;'>Total Crashes: {total_crashes:,}</h2>", unsafe_allow_html=True)

    st.subheader("Total Crash Counts by Region:")
    with st.expander("Show Crash Counts with a Bar Chart:"):
        all_regions_bar = sorted_regions_counts_df['REGC2025_1'].unique()
        selected_regions_bar = st.multiselect(
            "Select Region(s) to display in the bar chart:",
            options=all_regions_bar,
            default=list(all_regions_bar),
            key="bar_chart_region_selector"
        )
        bar_fig = create_bar_chart(
            sorted_regions_counts_df,
            selected_regions_bar,
            year_range=year_range,
            speed_range=speed_range,
            severity=selected_severity
        )
        if bar_fig:
            st.pyplot(bar_fig, use_container_width=True)
            buf = io.BytesIO()
            bar_fig.savefig(buf, format='png')
            st.download_button(
                label="Download Bar Chart as PNG",
                data=buf.getvalue(),
                file_name="bar_chart.png",
                mime="image/png"
            )
            st.markdown(
                f"<p style='text-align: center; font-size: 16px;'>Filters Applied: "
                f"<strong>Years:</strong> {year_range[0]}–{year_range[1]}, "
                f"<strong>Speed:</strong> {speed_range[0]}–{speed_range[1]} km/h, "
                f"<strong>Severity:</strong> {selected_severity}</p>",
                unsafe_allow_html=True
            )

    st.subheader("Yearly Crash Trends by Region:")
    with st.expander("Show Crash Trends Over Time with a Line Graph:"):
        all_regions = sorted(filtered_df['region'].unique())
        selected_regions = st.multiselect(
            "Select Region(s) to include in the line graph:",
            options=all_regions,
            default=all_regions
        )
        line_fig = create_line_chart_matplotlib(
            filtered_df,
            selected_regions,
            year_range=year_range,
            speed_range=speed_range,
            severity=selected_severity
        )
        if line_fig:
            st.pyplot(line_fig)
            buf = io.BytesIO()
            line_fig.savefig(buf, format='png')
            st.download_button(
                label="Download Line Graph as PNG",
                data=buf.getvalue(),
                file_name="line_graph.png",
                mime="image/png"
            )
            st.markdown(
                f"<p style='text-align: center; font-size: 16px;'>Filters Applied: "
                f"<strong>Years:</strong> {year_range[0]}–{year_range[1]}, "
                f"<strong>Speed:</strong> {speed_range[0]}–{speed_range[1]} km/h, "
                f"<strong>Severity:</strong> {selected_severity}</p>",
                unsafe_allow_html=True
            )

    st.subheader("Inspect the Filtered Dataset:")
    with st.expander("Show Filtered Dataset:"):
        filtered_data = csv_df[csv_df['crashYear'].between(year_range[0], year_range[1])]
        if selected_severity != "All Severities":
            filtered_data = filtered_data[filtered_data['crashSeverity'] == selected_severity]
        if speed_range:
            filtered_data = filtered_data[filtered_data['effective_speed'].between(speed_range[0], speed_range[1])]
        st.dataframe(filtered_data)
        st.download_button(
            label="Download Filtered Data as CSV",
            data=filtered_data.to_csv(index=False).encode('utf-8'),
            file_name=f"nz_crash_data_{year_range[0]}-{year_range[1]}.csv",
            mime='text/csv'
        )


if __name__ == "__main__":
    streamlit_app()