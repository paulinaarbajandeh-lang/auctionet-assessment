{{ config(
    materialized='table',
    schema='marts'
) }}

WITH cleaned_items AS (
    SELECT * FROM {{ ref('int_auctionet_items_cleaned') }}
),

ranked_items AS (
    SELECT
        item_id,
        title,
        description,
        condition,
        state,
        auction_type,
        placement,
        url,
        ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY ingested_at DESC) AS row_num
    FROM cleaned_items
)

SELECT
    item_id,
    title,
    description,
    condition,
    state,
    auction_type,
    placement,
    url
FROM ranked_items
WHERE row_num = 1