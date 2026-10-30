{{ config(
    materialized='view',
    schema='staging'
) }}

WITH items AS (
    SELECT
        item_id,
        bids,
        ingested_at
    FROM {{ ref('stg_auctionet_items') }}
),

flattened_bids AS (
    SELECT
        items.item_id,
        bid.value:id::STRING AS bid_id,
        bid.value:bidder::STRING AS bidder_id,
        bid.value:amount::NUMBER AS bid_amount,
        bid.value:your_bid::BOOLEAN AS your_bid,
        bid.value:reserve_met::BOOLEAN AS reserve_met,
        bid.value:auto::BOOLEAN AS auto_bid,
        bid.value:timestamp::NUMBER AS bid_timestamp_epoch,
        items.ingested_at
    FROM items,
    LATERAL FLATTEN(input => items.bids) bid
)

SELECT *
FROM flattened_bids