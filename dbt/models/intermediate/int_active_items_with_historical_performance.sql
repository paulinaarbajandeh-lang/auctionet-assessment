{{ config(
    materialized='view',
    schema='intermediate'
) }}

select
    a.item_id,
    a.company_id,
    a.category_id,
    a.estimate_sek,
    a.starting_bid_amount_sek,

    coalesce(b.bid_count, 0) as current_bid_count,

    c.parent_category_id as main_category_id,
    c.parent_category_name as main_category_name,

    h.house_name as auction_house,

    cp.ended_items as category_ended_items,
    cp.median_bid_count as category_median_bid_count,
    cp.median_hammer_vs_estimate_pct as category_median_hammer_vs_estimate_pct,
    cp.pct_above_estimate as category_pct_above_estimate,

    hp.ended_items as house_ended_items,
    hp.median_bid_count as house_median_bid_count,
    hp.median_hammer_vs_estimate_pct as house_median_hammer_vs_estimate_pct,
    hp.pct_above_estimate as house_pct_above_estimate

from {{ ref('fct_auctions') }} a

left join (
    select
        item_id,
        count(*) as bid_count
    from {{ ref('fct_bids') }}
    group by item_id
) b
    on a.item_id = b.item_id

left join {{ ref('dim_categories') }} c
    on a.category_id = c.category_id

left join {{ ref('dim_houses') }} h
    on a.company_id = h.company_id

left join {{ ref('int_historical_category_performance') }} cp
    on c.parent_category_id = cp.main_category_id

left join {{ ref('int_historical_house_performance') }} hp
    on a.company_id = hp.company_id