-- 1. SELECT DATABASE AND SCHEMA
-- Category data is stored in the RAW schema before being cleaned and transformed by dbt

USE DATABASE DBT_AUCTIONET;
USE SCHEMA RAW;


-- 2. CREATE CATEGORY STAGE
-- The external stage points to the folder containing category JSON files collected from Auctionet

CREATE STAGE IF NOT EXISTS DBT_AUCTIONET.RAW.AZURE_CATEGORIES_STAGE
    URL = 'azure://<STORAGE_ACCOUNT>.blob.core.windows.net/raw/categories/'
    STORAGE_INTEGRATION = AZURE_RAW_INTEGRATION
    FILE_FORMAT = DBT_AUCTIONET.RAW.FORMAT_JSON_RAW;


-- 3. CREATE RAW CATEGORY TABLE
-- JSON_DATA stores the original category data
-- FILE_PATH identifies the source file
-- INGESTED_AT records when the file was loaded

CREATE TABLE IF NOT EXISTS DBT_AUCTIONET.RAW.RAW_AUCTIONET_CATEGORIES (
    JSON_DATA VARIANT,
    FILE_PATH STRING,
    INGESTED_AT TIMESTAMP_NTZ
        DEFAULT CONVERT_TIMEZONE(
            'Europe/Stockholm',
            CURRENT_TIMESTAMP()
        )::TIMESTAMP_NTZ
);


-- 4. LOAD CATEGORY DATA
-- Read category JSON files from Azure Blob Storage and load them into the raw Snowflake table
-- This COPY INTO statement is intended for initial or manual ingestion of category data

COPY INTO DBT_AUCTIONET.RAW.RAW_AUCTIONET_CATEGORIES
    (JSON_DATA, FILE_PATH)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @DBT_AUCTIONET.RAW.AZURE_CATEGORIES_STAGE
);
