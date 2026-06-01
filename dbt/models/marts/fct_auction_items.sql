{{ config(materialized='table', schema='gold') }}

with staging as (
    select * from {{ ref('stg_auctionet_items') }}
)

select
    item_id,       -- FK to dim_items
    company_id,    -- FK to dim_companies
    auction_id,
    category_id,
    catalog_number,
    event_id,
    currency,
    is_reserve_met,
    reserve_amount,
    estimate_amount,
    upper_estimate_amount,
    starting_bid_amount,
    is_hammered,
    prefer_starting_bid_amount_to_estimate,
    next_bid_amount,
    ends_at,
    published_at,
    placement,
    file_path,
    ingested_at
from staging