{{ config(
    materialized='view',
    schema='intermediate'
) }}

WITH staging AS (
    SELECT * FROM {{ ref('stg_auctionet_items_current') }}
),

fx_rates AS (
    SELECT 'SEK' AS currency, 1.00 AS rate_to_sek
    UNION ALL
    SELECT 'EUR', 11.10
    UNION ALL
    SELECT 'GBP', 12.80
    UNION ALL
    SELECT 'DKK', 1.49
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
        s.currency as currency,
        estimate,
        upper_estimate,
        starting_bid_amount,
        -- Normalize monetary values to SEK
        estimate * fx.rate_to_sek AS estimate_sek,
        starting_bid_amount * fx.rate_to_sek AS starting_bid_amount_sek,
        next_bid_amount,
        reserve_amount,
        reserve_met,
        hammered,
        
        -- Convert Epoch UNIX integers to proper Snowflake Timestamps
        TO_TIMESTAMP_NTZ(ends_at_epoch) AS ends_at,
        TO_TIMESTAMP_NTZ(published_at_epoch) AS published_at,
        
        file_path,
        ingested_at
    FROM staging s
    LEFT JOIN fx_rates fx
        ON s.currency = fx.currency
)

SELECT * FROM cleaned