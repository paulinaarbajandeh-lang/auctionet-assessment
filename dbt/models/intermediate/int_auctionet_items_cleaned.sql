{{ config(
    materialized='view',
    schema='intermediate'
) }}

WITH staging AS (
    SELECT * FROM {{ ref('stg_auctionet_items') }}
),

cleaned AS (
    SELECT
        item_id,
        auction_id,
        company_id,
        category_id,
        title,
        
        -- Clean HTML tags from text fields
        TRIM(REGEXP_REPLACE(raw_description, '<[^>]+>', ' ')) AS description,
        TRIM(REGEXP_REPLACE(raw_condition, '<[^>]+>', ' ')) AS condition,
        
        state,
        auction_type,
        placement,
        url,
        house_name,
        location,
        currency,
        estimate,
        upper_estimate,
        starting_bid_amount,
        next_bid_amount,
        reserve_amount,
        reserve_met,
        hammered,
        
        -- Convert Epoch UNIX integers to proper Snowflake Timestamps
        TO_TIMESTAMP_NTZ(ends_at_epoch) AS ends_at,
        TO_TIMESTAMP_NTZ(published_at_epoch) AS published_at,
        
        file_path,
        ingested_at
    FROM staging
)

SELECT * FROM cleaned