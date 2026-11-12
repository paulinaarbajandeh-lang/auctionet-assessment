-- A. CREAT A BRIDGE TO AZURE

-- Create the secure bridge to Azure ADLS Gen2
CREATE OR REPLACE STORAGE INTEGRATION azure_raw_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  ENABLED = TRUE
  AZURE_TENANT_ID = 'd236863a-f43f-4500-9e6d-8a195ae609f8'
  STORAGE_ALLOWED_LOCATIONS = ('azure://saauctionetassessment.blob.core.windows.net/raw');

-- Inspect integration
DESCRIBE STORAGE INTEGRATION azure_raw_integration;


-------------------------------------------------------------------------------------------

-- B. CREATE EXTERNAL STAGE

-- Grant SYSADMIN role permission to use the security integration
GRANT USAGE ON INTEGRATION azure_raw_integration TO ROLE SYSADMIN;
GRANT CREATE STAGE ON SCHEMA DEV_BRONZE.AUCTIONET TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE DEV_BRONZE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA DEV_BRONZE.AUCTIONET TO ROLE SYSADMIN;
GRANT CREATE STAGE ON SCHEMA DEV_BRONZE.AUCTIONET TO ROLE SYSADMIN;


-- DDL statement to build the staging zone inside the FORMULAONE schema
-- Create the external stage pointing to the raw container
CREATE OR REPLACE STAGE DEV_BRONZE.AUCTIONET.ext_stage_raw
  STORAGE_INTEGRATION = azure_raw_integration
  URL = 'azure://saauctionetassessment.blob.core.windows.net/raw'
  FILE_FORMAT = (TYPE = 'JSON'); -- Automatically pre-configures this stage for raw JSON files

-- Check connection
LIST @DEV_BRONZE.AUCTIONET.ext_stage_raw;

-------------------------------------------------------------------------------------------------
-- C. CREATE QUEUE INTEGRATION

CREATE OR REPLACE NOTIFICATION INTEGRATION azure_event_grid_integration
  ENABLED = TRUE
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
  AZURE_TENANT_ID = 'd236863a-f43f-4500-9e6d-8a195ae609f8'
  AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://saauctionetassessment.queue.core.windows.net/queue-auctionet-snowflake';

-- Check integration
DESCRIBE NOTIFICATION INTEGRATION azure_event_grid_integration;

