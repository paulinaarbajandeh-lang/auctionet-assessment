{{ config(
    materialized='view'
) }}

WITH silver_source AS (
    SELECT * from {{ source('auctionet', 'silver_auctionet') }}
),

latest_items AS (
    SELECT
        item_id,
        auction_id,
        category_id,
        title,
        auction_type,
        published_at,
        ends_at
    FROM silver_source
    -- Deduplicate to keep only the most recent snapshot of each item
    QUALIFY ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY load_timestamp DESC) = 1
)

SELECT * FROM latest_items