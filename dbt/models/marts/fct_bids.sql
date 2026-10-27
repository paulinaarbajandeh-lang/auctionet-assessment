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
)

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