{{ config(
    materialized='table',
    schema='marts'
) }}

WITH cleaned_items AS (
    SELECT * FROM {{ ref('int_auctionet_items_cleaned') }}
)

SELECT
    item_id,
    auction_id,
    company_id,
    category_id,
    currency,
    reserve_met,
    hammered,
    estimate,
    upper_estimate,
    starting_bid_amount,
    next_bid_amount,
    reserve_amount,
    published_at,
    ends_at,
    ingested_at
FROM cleaned_items