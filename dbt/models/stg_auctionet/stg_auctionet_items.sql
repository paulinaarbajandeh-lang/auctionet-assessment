{{ config(materialized='view', schema='silver_space') }}

with raw_source as (
    select * from {{ source('bronze_auctionet', 'raw_auctionet') }}
),

-- Flatten the outer 'items' array inside your raw VARIANT object
flattened as (
    select
        file_path,
        ingested_at,
        value as item
    from raw_source,
    lateral flatten(input => json_data:items)
),

renamed as (
    select
        (item:id)::int as item_id,
        (item:catalog_number)::string as catalog_number,
        (item:auction_id)::int as auction_id,
        (item:event_id)::int as event_id,
        (item:currency)::string as currency,
        (item:reserve_met)::boolean as is_reserve_met,
        (item:reserve_amount)::numeric(16,2) as reserve_amount,
        (item:estimate)::numeric(16,2) as estimate_amount,
        (item:upper_estimate)::numeric(16,2) as upper_estimate_amount,
        (item:starting_bid_amount)::numeric(16,2) as starting_bid_amount,
        (item:hammered)::boolean as is_hammered,
        (item:prefer_starting_bid_amount_to_estimate)::boolean as prefer_starting_bid_amount_to_estimate,
        (item:next_bid_amount)::numeric(16,2) as next_bid_amount,
        (item:state)::string as item_state,
        (item:title)::string as item_title,
        (item:description)::string as item_description,
        (item:condition)::string as item_condition,
        (item:company_id)::int as company_id,
        (item:category_id)::int as category_id,
        -- Conversion of Epoch timestamps to standard Snowflake NTZ
        to_timestamp_ntz((item:ends_at)::int) as ends_at,
        to_timestamp_ntz((item:published_at)::int) as published_at,
        (item:type)::string as auction_type,
        (item:location)::string as location,
        (item:house)::string as auction_house,
        (item:placement)::string as placement,
        (item:url)::string as item_url,
        file_path,
        ingested_at
    from flattened
)

select * from renamed
-- FIX: Only keep the latest record per item_id based on the ingestion timestamp
qualify row_number() over (partition by item_id order by ingested_at desc) = 1