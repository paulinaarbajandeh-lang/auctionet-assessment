{{ config(
    materialized='table',
    schema='marts'
) }}

WITH current_bids AS (

    SELECT
        i.item_id,
        b.value:id::STRING AS bid_id,
        b.value:bidder::STRING AS bidder_id,
        b.value:amount::NUMBER AS bid_amount,
        b.value:your_bid::BOOLEAN AS your_bid,
        b.value:reserve_met::BOOLEAN AS reserve_met,
        b.value:auto::BOOLEAN AS auto_bid,
        b.value:timestamp::NUMBER AS bid_timestamp_epoch,
        i.ingested_at

    FROM {{ ref('stg_auctionet_items_current') }} i,
    LATERAL FLATTEN(input => i.bids) b

),

deduplicated AS (

    SELECT *
    FROM current_bids
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY bid_id
        ORDER BY ingested_at DESC
    ) = 1

)

SELECT *
FROM deduplicated