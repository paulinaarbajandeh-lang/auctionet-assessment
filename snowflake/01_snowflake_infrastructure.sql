-- 1. DATABASE AND SCHEMA
-- Create the database and RAW schema if they do not exist
-- RAW stores the original JSON data before dbt transformations

CREATE DATABASE IF NOT EXISTS DBT_AUCTIONET;

CREATE SCHEMA IF NOT EXISTS DBT_AUCTIONET.RAW;

USE DATABASE DBT_AUCTIONET;
USE SCHEMA RAW;


-- 2. AZURE STORAGE INTEGRATION
-- Establish a secure connection between Snowflake and Azure Blob Storage without embedding storage credentials
-- The Azure tenant ID and storage account are represented by placeholders for public GitHub documentation
-- Azure-side permissions must also be configured separately

CREATE STORAGE INTEGRATION IF NOT EXISTS AZURE_RAW_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'AZURE'
    ENABLED = TRUE
    AZURE_TENANT_ID = '<AZURE_TENANT_ID>'
    STORAGE_ALLOWED_LOCATIONS = (
        'azure://<STORAGE_ACCOUNT>.blob.core.windows.net/raw/'
    );

-- 3. JSON FILE FORMAT
-- Define how Snowflake interprets JSON files collected from the Auctionet API

CREATE FILE FORMAT IF NOT EXISTS DBT_AUCTIONET.RAW.FORMAT_JSON_RAW
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = TRUE;

-- 4. AZURE EXTERNAL STAGES
-- Stages provide Snowflake with access to JSON files stored in Azure Blob Storage
-- AZURE_RAW_STAGE: References the raw storage container
-- AZURE_PAGINATED_STAGE: References paginated item data collected by ADF

CREATE STAGE IF NOT EXISTS DBT_AUCTIONET.RAW.AZURE_RAW_STAGE
    URL = 'azure://<STORAGE_ACCOUNT>.blob.core.windows.net/raw/'
    STORAGE_INTEGRATION = AZURE_RAW_INTEGRATION
    FILE_FORMAT = DBT_AUCTIONET.RAW.FORMAT_JSON_RAW;

CREATE STAGE IF NOT EXISTS DBT_AUCTIONET.RAW.AZURE_PAGINATED_STAGE
    URL = 'azure://<STORAGE_ACCOUNT>.blob.core.windows.net/raw/paginated/'
    STORAGE_INTEGRATION = AZURE_RAW_INTEGRATION
    FILE_FORMAT = DBT_AUCTIONET.RAW.FORMAT_JSON_RAW;


-- 5. RAW DATA TABLES
-- Store API responses as semi-structured JSON (VARIANT).
-- JSON_DATA: Original JSON payload from Auctionet 
-- FILE_PATH: Identifies the source file in Azure Blob Storage
-- INGESTED_AT: Records when Snowflake ingested the data, using Swedish local time
-- Original/raw API responses

CREATE TABLE IF NOT EXISTS DBT_AUCTIONET.RAW.RAW_AUCTIONET (
    JSON_DATA VARIANT,
    FILE_PATH STRING,
    INGESTED_AT TIMESTAMP_NTZ
        DEFAULT CONVERT_TIMEZONE(
            'Europe/Stockholm',
            CURRENT_TIMESTAMP()
        )::TIMESTAMP_NTZ
);


-- Paginated active auction data
-- Historical snapshots are retained across ingestion runs

CREATE TABLE IF NOT EXISTS DBT_AUCTIONET.RAW.RAW_AUCTIONET_PAGINATED (
    JSON_DATA VARIANT,
    FILE_PATH STRING,
    INGESTED_AT TIMESTAMP_NTZ
        DEFAULT CONVERT_TIMEZONE(
            'Europe/Stockholm',
            CURRENT_TIMESTAMP()
        )::TIMESTAMP_NTZ
);
