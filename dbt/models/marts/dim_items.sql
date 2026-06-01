{{ config(materialized='table', schema='gold') }}

with staging as (
    select * from {{ ref('stg_auctionet_items') }}
)

select distinct
    item_id,
    item_title,
    item_description,
    item_condition,
    item_state,
    auction_type,
    item_url
from staging