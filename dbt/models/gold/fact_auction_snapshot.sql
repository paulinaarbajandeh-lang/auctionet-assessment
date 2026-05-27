{{ config(
    materialized='view'
) }}

WITH silver_source AS (
    SELECT * from {{ source('auctionet', 'silver_auctionet') }}
)

SELECT
    item_id,              -- Foreign key to dim_item
    company_id,           -- Foreign key to dim_house
    load_timestamp,       -- Degenerate dimension / Snapshot timestamp
    state,
    hammered,
    reserve_met,
    reserve_amount,
    estimate,
    starting_bid_amount,
    next_bid_amount
FROM silver_source