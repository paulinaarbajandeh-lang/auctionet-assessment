select
    item_id,
    auction_id,
    estimate,
    currency,
    estimate_sek,
    bid_count,
    hammer_price_sek,
    hammer_vs_estimate_sek,
    hammer_to_estimate_ratio,
    hammer_vs_estimate_pct,
    auction_end_time,
    reserve_met,
    has_bid_count,
    sale_format,
    url
from {{ ref('int_auctionet_ended_cleaned') }}