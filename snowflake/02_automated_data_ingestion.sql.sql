-- 1. AZURE NOTIFICATION INTEGRATION
-- Connect Snowflake to an Azure Storage Queue
-- Azure Event Grid sends notifications when new files arrive in Blob Storage
-- Snowflake reads these notifications to identify files ready for ingestion
-- Placeholders are used for Azure-specific identifiers in the public GitHub documentation
-- Creating integrations requires appropriate privileges

CREATE NOTIFICATION INTEGRATION IF NOT EXISTS
    AZURE_EVENT_GRID_INTEGRATION
    ENABLED = TRUE
    TYPE = QUEUE
    NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
    AZURE_TENANT_ID = '<AZURE_TENANT_ID>'
    AZURE_STORAGE_QUEUE_PRIMARY_URI =
        'https://<STORAGE_ACCOUNT>.queue.core.windows.net/<QUEUE_NAME>';


-- 2. SELECT DATABASE AND SCHEMA
-- The RAW schema contains the destination table and the Azure external stage
-- These objects are defined separately in 01_snowflake_infrastructure.sql

USE DATABASE DBT_AUCTIONET;
USE SCHEMA RAW;

-- 3. CREATE SNOWPIPE
-- Snowpipe automatically loads newly detected JSON files from the paginated Azure Blob Storage stage
-- AUTO_INGEST = TRUE enables event-driven ingestion
-- The COPY statement:
-- 1. Reads each JSON payload as a VARIANT value
-- 2. Records the originating filename
-- 3. Inserts both values into the RAW table
-- INGESTED_AT is populated by the table's default value
-- IF NOT EXISTS avoids replacing an existing pipe

CREATE PIPE IF NOT EXISTS
    DBT_AUCTIONET.RAW.AUCTIONET_PAGINATED_PIPE
    AUTO_INGEST = TRUE
    INTEGRATION = 'AZURE_EVENT_GRID_INTEGRATION'
AS
COPY INTO DBT_AUCTIONET.RAW.RAW_AUCTIONET_PAGINATED
    (JSON_DATA, FILE_PATH)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @DBT_AUCTIONET.RAW.AZURE_PAGINATED_STAGE
);
