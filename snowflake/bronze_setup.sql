-- ==========================================
-- 1. CLEAN UP OLD PIPES
-- ==========================================
DROP PIPE IF EXISTS dbt_auctionet.bronze.pipe_auctionet;

-- ==========================================
-- 2. CORE DATABASE, SCHEMA & FILE FORMAT SETUP
-- ==========================================
CREATE DATABASE IF NOT EXISTS dbt_auctionet;
CREATE SCHEMA IF NOT EXISTS dbt_auctionet.bronze;
USE SCHEMA dbt_auctionet.bronze;

-- Shared high-performance JSON format
CREATE OR REPLACE FILE FORMAT dbt_auctionet.bronze.format_json_raw
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = TRUE;


-- ==========================================
-- 3. EXTERNAL STAGE CONFIGURATION (FIXED PATH)
-- ==========================================
-- The first /raw/ is the Azure Container. The second /raw/ is your folder.
CREATE OR REPLACE STAGE dbt_auctionet.bronze.azure_raw_stage
    URL = 'azure://saauctionetassessment.blob.core.windows.net/raw/'  
    STORAGE_INTEGRATION = azure_raw_integration
    FILE_FORMAT = dbt_auctionet.bronze.format_json_raw;


-- ==========================================
-- 4. TARGET RAW APPEND-ONLY TABLES
-- ==========================================
CREATE OR REPLACE TABLE dbt_auctionet.bronze.raw_auctionet (
    json_data VARIANT,
    file_path STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CONVERT_TIMEZONE('Europe/Stockholm', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ 
);

-- ==========================================
-- 5. DEPLOY AUTOMATED AUTO-INGEST SNOWPIPES
-- ==========================================

-- 1. Pipe for OpenWeather Data (looks in /raw/raw/weather/)
CREATE OR REPLACE PIPE dbt_auctionet.bronze.pipe_auctionet
    AUTO_INGEST = TRUE
    INTEGRATION = 'AZURE_EVENT_GRID_INTEGRATION'
AS
COPY INTO dbt_auctionet.bronze.raw_auctionet (json_data, file_path)
FROM (
    SELECT $1, METADATA$FILENAME 
    FROM @dbt_auctionet.bronze.azure_raw_stage/
);


-- ==========================================
-- 6. KICKSTART PIPES & LOAD PRE-EXISTING DATA
-- ==========================================
-- Forces Snowpipes to inspect your exact paths right now and load existing files
ALTER PIPE dbt_auctionet.bronze.pipe_auctionet REFRESH;



-- ==========================================
-- 7. PRODUCTION VERIFICATION & QUALITY CHECKS
-- ==========================================
-- First, verify Snowflake can actually see the files in your nested 'raw/raw/' folders:
LIST @dbt_auctionet.bronze.azure_raw_stage/;

-- Wait about 10-15 seconds after the refresh, then check your table counts:
SELECT COUNT(*) AS auctionet_total FROM dbt_auctionet.bronze.raw_auctionet;
