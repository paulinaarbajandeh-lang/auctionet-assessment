{{ config(
    materialized='view',
    schema='staging'
) }}

WITH source AS (
    SELECT * FROM {{ source('auctionet_raw', 'raw_auctionet') }}
),

flattened AS (
    SELECT
        -- Primary Keys & Identifiers
        f.value:id::STRING AS item_id,
        f.value:auction_id::STRING AS auction_id,
        f.value:company_id::STRING AS company_id,
        f.value:category_id::STRING AS category_id,
        
        -- Text Attributes
        f.value:title::STRING AS title,
        f.value:description::STRING AS raw_description,
        f.value:condition::STRING AS raw_condition,
        f.value:state::STRING AS state,
        f.value:type::STRING AS auction_type,
        f.value:placement::STRING AS placement,
        f.value:url::STRING AS url,
        
        -- House & Location Info
        f.value:house::STRING AS house_name,
        f.value:location::STRING AS location,
        
        -- Metrics & Financials
        f.value:currency::STRING AS currency,
        f.value:estimate::NUMBER AS estimate,
        f.value:upper_estimate::NUMBER AS upper_estimate,
        f.value:starting_bid_amount::NUMBER AS starting_bid_amount,
        f.value:next_bid_amount::NUMBER AS next_bid_amount,
        f.value:reserve_amount::NUMBER AS reserve_amount,
        f.value:reserve_met::BOOLEAN AS reserve_met,
        f.value:hammered::BOOLEAN AS hammered,
        
        -- Timestamps (Epoch seconds)
        f.value:ends_at::NUMBER AS ends_at_epoch,
        f.value:published_at::NUMBER AS published_at_epoch,
        
        -- Metadata
        file_path,
        ingested_at
    FROM source,
    LATERAL FLATTEN(input => json_data:items) f
)

SELECT * FROM flattened