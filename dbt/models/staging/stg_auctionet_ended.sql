select
    item_id,
    auction_id,
    estimate,
    currency,
    bid_count,
    hammer_price_sek,
    auction_end_time,
    reserve_met,
    url,
    source_page,
    has_bid_count,
    sale_format
from {{ source('auctionet_raw', 'raw_auctionet_ended') }}