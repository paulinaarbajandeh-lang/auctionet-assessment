-- ==========================================
-- 1. CLEAN UP OLD PIPES
-- ==========================================
-- DROP PIPE IF EXISTS dbt_auctionet.raw.pipe_auctionet;

-- ==========================================
-- 2. CORE DATABASE, SCHEMA & FILE FORMAT SETUP
-- ==========================================
CREATE DATABASE IF NOT EXISTS dbt_auctionet;
CREATE SCHEMA IF NOT EXISTS dbt_auctionet.raw;
USE SCHEMA dbt_auctionet.raw;

-- JSON file format for Auctionet API responses
CREATE OR REPLACE FILE FORMAT dbt_auctionet.raw.format_json_raw
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = TRUE;

-- ==========================================
-- 3. EXTERNAL STAGE CONFIGURATION
-- ==========================================
-- Points to the raw container in Azure Blob Storage where ADF drops JSON files
CREATE OR REPLACE STAGE dbt_auctionet.raw.azure_raw_stage
    URL = 'azure://saauctionetassessment.blob.core.windows.net/raw/'  
    STORAGE_INTEGRATION = azure_raw_integration
    FILE_FORMAT = dbt_auctionet.raw.format_json_raw;

-- ==========================================
-- 4. TARGET RAW APPEND-ONLY TABLES
-- ==========================================
-- Stores raw Auctionet JSON payloads as-is, one row per ingested file
CREATE OR REPLACE TABLE dbt_auctionet.raw.raw_auctionet (
    json_data VARIANT,
    file_path STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CONVERT_TIMEZONE('Europe/Stockholm', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ 
);

-- ==========================================
-- 5. DEPLOY AUTOMATED AUTO-INGEST SNOWPIPES
-- ==========================================
-- Listens to Azure Event Grid notifications and automatically loads
-- new JSON files from Blob Storage into raw_auctionet as they arrive
CREATE OR REPLACE PIPE dbt_auctionet.raw.pipe_auctionet
    AUTO_INGEST = TRUE
    INTEGRATION = 'AZURE_EVENT_GRID_INTEGRATION'
AS
COPY INTO dbt_auctionet.raw.raw_auctionet (json_data, file_path)
FROM (
    SELECT $1, METADATA$FILENAME 
    FROM @dbt_auctionet.raw.azure_raw_stage/
);

-- ==========================================
-- 6. KICKSTART PIPES & LOAD PRE-EXISTING DATA
-- ==========================================
-- Run this once after pipe creation to load any files already in Blob Storage
-- ALTER PIPE dbt_auctionet.raw.pipe_auctionet REFRESH;

-- ==========================================
-- 7. PRODUCTION VERIFICATION & QUALITY CHECKS
-- ==========================================
-- Verify Snowflake can see the files in the Azure Blob Storage raw container
LIST @dbt_auctionet.raw.azure_raw_stage/;

-- Check total number of rows loaded into the raw table
SELECT COUNT(*) AS auctionet_total FROM dbt_auctionet.raw.raw_auctionet;
