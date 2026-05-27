{{ config(
    materialized='view'
) }}

WITH silver_source AS (
    SELECT * from {{ source('auctionet', 'silver_auctionet') }}
),

latest_houses AS (
    SELECT
        company_id,
        house,
        location,
        currency
    FROM silver_source
    WHERE company_id IS NOT NULL
    -- Deduplicate to keep only the most recent details for each company
    QUALIFY ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY load_timestamp DESC) = 1
)

SELECT * FROM latest_houses