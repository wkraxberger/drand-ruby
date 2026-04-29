# drand

[![Gem Version](https://img.shields.io/gem/v/drand.svg)](https://rubygems.org/gems/drand)
[![Downloads](https://img.shields.io/gem/dt/drand.svg)](https://rubygems.org/gems/drand)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ruby client for [drand](https://drand.love), the public randomness beacon run by the League of Entropy.

> Unofficial. Not affiliated with the drand project or the League of Entropy.

Mainly a timestamp to round number helper. Optionally fetches round values over HTTP.

## Install

```sh
gem install drand
```

Or in a Gemfile:

```ruby
gem "drand"
```

Requires Ruby 3.2+. Pulls in [`bls12-381`](https://rubygems.org/gems/bls12-381) for signature verification.

## Usage

```ruby
require "drand"

chain = Drand.chain(:quicknet)   # or :default for the 30 second mainnet

# round math, pure, no network
chain.round_at(Time.utc(2026, 4, 20))               # => 27946612
chain.round_at(Time.utc(2026, 4, 20, 12, 30, 45))   # => 27961627
chain.time_of(27946612)                             # => 2026-04-20 00:00:00 UTC
chain.current_round                                 # => current round number

# fetch a round's value from the API (signature is verified by default)
chain.round(27946612)
# => { round: 27946612, randomness: ..., signature: ..., previous_signature: nil, verified: true, served_by: "https://api.drand.sh" }
```

Known chains try several official mirrors (`api.drand.sh`, `api2.drand.sh`, `api3.drand.sh`, `drand.cloudflare.com`) and fall back if one is down. The endpoint that actually responded is returned in the `served_by` key.

Pin to a single endpoint:

```ruby
Drand.chain(:quicknet, base_url: "https://api.drand.sh")
```

Supply your own mirror list:

```ruby
Drand.chain(:quicknet, endpoints: ["https://my-mirror.example", "https://api.drand.sh"])
```

Custom chain:

```ruby
Drand::Chain.new(chain_hash: "...", genesis_time: 1_700_000_000, period: 10)
```

### Signature verification

> Verification is implemented on top of the [`bls12-381`](https://rubygems.org/gems/bls12-381) gem, which is **not audited**. It has passed the same tests as [`noble-bls12-381`](https://github.com/paulmillr/noble-bls12-381), but don't treat a `verified: true` result as a substitute for a vetted, audited cryptographic implementation in adversarial settings.

Both `:quicknet` and `:default` ship with the chain's public key embedded, and rounds are verified automatically:

```ruby
chain = Drand.chain(:quicknet)
chain.round(27_946_612)[:verified]   # => true
```

A bogus or tampered round raises `Drand::VerificationError`:

```ruby
chain.round(27_946_612)              # raises if the signature does not check out
chain.round(27_946_612, verify: false)  # opt out, returns verified: false
```

Verification supports drand's two production schemes:

- `bls-unchained-g1-rfc9380` — quicknet (G1 signatures, G2 public keys, message = `SHA256(round)`)
- `pedersen-bls-chained` — default mainnet (G2 signatures, G1 public keys, message = `SHA256(prev_signature || round)`)

Custom chains have no embedded key, so they default to `verify: false`. Pass `public_key:` and `scheme:` to enable verification:

```ruby
chain = Drand::Chain.new(
  chain_hash:   "...",
  genesis_time: 1_700_000_000,
  period:       10,
  scheme:       Drand::Verifier::UNCHAINED_G1,
  public_key:   "83cf0f..."
)
chain.round(123)[:verified]   # => true
```

You can also verify a round dict directly:

```ruby
chain.verify(round: 1000, signature: "b446...", previous_signature: nil)
# => true / false
```

### Drawing a verifiable random number

Publicly verifiable, deterministic integer derived from a drand round. Same round with same range always gives the same value.

```ruby
chain.draw(1..6)
# => {
#      value:      4,
#      range:      { min: 1, max: 6 },
#      round:      27_971_460,
#      chain:      "quicknet",
#      chain_hash: "52db9ba70e...e971",
#      randomness: "b33732d25aa4...",
#      signature:  "8c38d1e6f0...",
#      verified:   false,
#      served_by:  "https://api.drand.sh"
#    }

chain.draw(1..100, round: 27_000_000)   # specific round
```

Or on the 30 second mainnet:

```ruby
Drand.chain(:default).draw(1..6)
```

Anyone with the returned hash can reproduce the value by fetching the same round and running the same sampling. If you just want the integer, `chain.draw(1..6)[:value]`.

Rejection sampling over a SHA 256 byte stream, so no modulo bias.

## Notes

Same round + same range = same result. That's the feature, not a bug. The whole point of drand is that the draw is reproducible by anyone. Quicknet ticks every 3 seconds, default mainnet every 30, so repeated calls within that window hand you back the exact same number until the round advances.

Because of that, this gem isn't a good fit if you need lots of random numbers in a short amount of time. It's built for things like lottery draws, prize picks, or anything where the randomness has to be auditable. For everyday `rand` style needs, use `Kernel#rand` or `SecureRandom`.

A note on naming: this gem defaults to `quicknet`, The 30 second mainnet is somewhat confusingly named `default` by drand itself. If you want that chain, select it explicitly with `Drand.chain(:default)`. `quicknet` is the gem default because a 3 second cadence will likely be more useful for most users.

## License

MIT.
