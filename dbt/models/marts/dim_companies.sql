{{ config(materialized='table', schema='gold') }}

with staging as (
    select * from {{ ref('stg_auctionet_items') }}
)

select distinct
    company_id,
    auction_house,
    location
from staging