# Written for Danu, 2022

import random

import cachetools


# Generate uniformally distributed floating-point numbers
# - Interval for fair-market price, see https://docs.python.org/3/library/random.html#random.random
VAL_A           = 1e-2
VAL_B           = 1.50
# - Interval for liquidation price
VAL_C           = 0.5
VAL_D           = 0.8
# - Maximum number of NFTs to cache
CACHE_MAXSIZE   = 1000
# - Timeout, to prevent prices from changing too often
CACHE_TIMEOUT   = 10  # in seconds


@cachetools.cached(cache = cachetools.TTLCache(
    maxsize = CACHE_MAXSIZE,
    ttl = CACHE_TIMEOUT
))
def appraise(address: str, token_ID: int) -> dict:
    """Simplest possible pricing model we could come up with"""

    fair_market_price: float = random.uniform(VAL_A, VAL_B)

    print("Test")

    return {
            "fair-market_price": fair_market_price,
            "liquidation_price": random.uniform(VAL_C, VAL_D) * fair_market_price,
            "currency": "ETH"
    }

