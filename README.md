# drand

Ruby client for [drand](https://drand.love), the public randomness beacon run by the League of Entropy.

> Unofficial. Not affiliated with the drand project or the League of Entropy.

Mainly a timestamp to round number helper. Optionally fetches round values over HTTP.

## Install

```ruby
gem "drand"
```

Requires Ruby 3.2+. No runtime dependencies.

## Usage

```ruby
require "drand"

chain = Drand.chain(:quicknet)   # or :default for the 30s mainnet

chain.round_at(Time.utc(2026, 4, 20))   # => 27946612
chain.time_of(27946612)                 # => 2026-04-20 00:00:00 UTC
chain.current_round
chain.round(27946612)                   # hits https://api.drand.sh
# => { round: 27946612, randomness: ..., signature: ..., previous_signature: nil, verified: false }
```

Custom chain:

```ruby
Drand::Chain.new(chain_hash: "...", genesis_time: 1_700_000_000, period: 10)
```

### Drawing a verifiable random number

Publicly verifiable, deterministic integer derived from a drand round. Same round with same range always gives the same value.

```ruby
chain = Drand.chain(:quicknet)

chain.draw(1..6)
# => {
#      value:      4,
#      range:      { min: 1, max: 6 },
#      round:      27_971_460,
#      chain:      "quicknet",
#      chain_hash: "52db9ba70e...e971",
#      randomness: "b33732d25aa4...",
#      signature:  "8c38d1e6f0...",
#      verified:   false
#    }

chain.draw(1..100, round: 27_000_000)   # specific round
```

Or use the 30 second mainnet:

```ruby
Drand.chain(:default).draw(1..6)
```

Anyone with the returned hash can reproduce the value by fetching the same round and running the same sampling. If you just want the integer, `chain.draw(1..6)[:value]`.

Rejection sampling over a SHA 256 byte stream, so no modulo bias.

## Notes

Signature verification isn't implemented yet, so fetched rounds carry `verified: false`. Don't rely on them as cryptographically checked.

Same round + same range = same result. That's the feature, not a bug. The whole point of drand is that the draw is reproducible by anyone. Quicknet ticks every 3 seconds, default mainnet every 30, so repeated calls within that window hand you back the same number until the round advances.

Because of that, this gem isn't a good fit if you need lots of random numbers in a short amount of time. It's built for things like lottery draws, prize picks, or anything where the randomness has to be auditable. For everyday `rand`-style needs, use `Kernel#rand` or `SecureRandom`.

## License

MIT.
