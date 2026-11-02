{{ config(
    materialized='view',
    schema='intermediate'
) }}

select
    main_category_id,
    main_category_name,

    count(*) as ended_items,

    avg(bid_count) as avg_bid_count,
    median(bid_count) as median_bid_count,

    avg(hammer_vs_estimate_pct) as avg_hammer_vs_estimate_pct,
    median(hammer_vs_estimate_pct) as median_hammer_vs_estimate_pct,

    avg(
        case
            when hammer_vs_estimate_pct > 0 then 1
            else 0
        end
    ) as pct_above_estimate

from {{ ref('fct_ended_auctions') }}

where main_category_id is not null
  and main_category_name is not null

group by
    main_category_id,
    main_category_name