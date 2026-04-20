# drand

Ruby client for [drand](https://drand.love), the public randomness beacon run by the League of Entropy.

> Unofficial. Not affiliated with the drand project or the League of Entropy.

Mainly a timestamp-to-round-number helper. Optionally fetches round values over HTTP.

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

## Notes

Signature verification isn't implemented yet, so fetched rounds carry `verified: false`. Don't rely on them as cryptographically checked.

## License

MIT.
