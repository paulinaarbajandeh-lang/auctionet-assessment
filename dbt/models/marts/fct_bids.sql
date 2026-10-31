{{ config(
    materialized='table',
    schema='marts'
) }}

WITH bids AS (
    SELECT
        item_id,
        bid_id,
        bidder_id,
        bid_amount,
        your_bid,
        reserve_met,
        auto_bid,
        bid_timestamp_epoch,
        ingested_at,

        ROW_NUMBER() OVER (
            PARTITION BY bid_id
            ORDER BY ingested_at DESC
        ) AS row_num

    FROM {{ ref('stg_auctionet_bids') }}
),

deduplicated_bids AS (
    SELECT
        item_id,
        bid_id,
        bidder_id,
        bid_amount,
        your_bid,
        reserve_met,
        auto_bid,
        bid_timestamp_epoch,
        ingested_at
    FROM bids
    WHERE row_num = 1
),

current_items AS (
    SELECT item_id
    FROM {{ ref('dim_items') }}
)

SELECT
    b.item_id,
    b.bid_id,
    b.bidder_id,
    b.bid_amount,
    b.your_bid,
    b.reserve_met,
    b.auto_bid,
    b.bid_timestamp_epoch,
    b.ingested_at

FROM deduplicated_bids b

INNER JOIN current_items c
    ON b.item_id = c.item_id