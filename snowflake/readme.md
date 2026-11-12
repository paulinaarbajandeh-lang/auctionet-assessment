# Snowflake: Data Ingestion and Model Evaluation

This folder contains the SQL scripts used to document the Snowflake setup, data ingestion and quality checks for the Auctionet Data Analytics project.

## Overview

Snowflake serves as the data warehouse between Azure Blob Storage and dbt. Auction data is collected through Azure Data Factory, stored as JSON files in Azure Blob Storage and loaded into Snowflake for further transformation and analysis.

The pipeline follows this structure:

**Auctionet API → Azure Data Factory → Azure Blob Storage → Snowflake → dbt → Power BI**

Snowpipe supports automated ingestion of active auction data through Azure event notifications. Historical auction data is also stored in Snowflake and used to enrich the prioritisation model with category- and auction-house-level performance.

## SQL Files

| File | Description |
|---|---|
| `01_snowflake_infrastructure.sql` | Sets up the database, RAW schema, Azure storage integration, JSON file format, external stages and raw tables. |
| `02_automated_data_ingestion.sql` | Documents the Azure notification integration and Snowpipe configuration for automated ingestion of paginated auction data. |
| `03_category_data_ingestion.sql` | Defines the stage, raw table and loading process for Auctionet category data. |
| `04_historical_auction_ingestion.sql` | Planned documentation of the final historical auction data ingestion process. |
| `05_data_quality_and_model_evaluation.sql` | Contains checks for data quality, historical coverage, score components, ranking comparisons and weight sensitivity. |

## Data Quality and Model Evaluation

The SQL checks support the evaluation of the rule-based prioritisation model by examining:

- Data completeness, duplicates and currency conversions.
- Historical data coverage across categories and auction houses.
- The distribution and components of prioritisation scores.
- Differences between model-based and bid-count-based rankings.
- Top 100 overlap under alternative weighting scenarios.
- Next-day Top 10 selection and raw data freshness.

The weighting scenarios compared are **50/25/25**, **60/20/20** and **40/30/30**, representing the relative importance of bidder engagement, historical category performance and historical auction-house performance.

These comparisons assess how the recommended selection changes under different assumptions. They do not establish a causal improvement in auction outcomes.

## Notes

The SQL scripts are provided for documentation and reproducibility. Environment-specific Azure identifiers have been replaced with placeholders in the public repository. Some scripts contain setup statements and should not be executed against an existing environment without review.

The `archive/` folder, if present, contains scripts from an earlier development environment. These are retained for reference and are not part of the current pipeline.

dbt transformations are maintained separately in the [`dbt/`](../dbt/) folder.
