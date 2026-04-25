# Changelog

## 0.3.0

BLS signature verification, backed by [`bls12-381`](https://rubygems.org/gems/bls12-381) (>= 0.3.1, the first release that runs on Ruby 3.4).

`Drand.chain(:quicknet)` and `Drand.chain(:default)` now ship with the chain's public key embedded and verify the BLS signature on every fetched round by default. Verified rounds come back with `verified: true`; tampered or bogus signatures raise `Drand::VerificationError`. Pass `verify: false` to `#round` or `#draw` to skip verification.

Quicknet uses the `bls-unchained-g1-rfc9380` scheme (G1 signatures, G2 public keys, `SHA256(round)`); default mainnet uses `pedersen-bls-chained` (G2 signatures, G1 public keys, `SHA256(prev_signature || round)`).

`Drand::Chain.new` now also accepts `scheme:` and `public_key:` for custom chains. `Drand::Verifier.verify(...)` is exposed for direct use.

Note: `bls12-381` is not audited. It passes the same test vectors as `noble-bls12-381`, but a `verified: true` result here should not be treated as equivalent to an audited cryptographic implementation in adversarial settings.

## 0.2.0

Known chains (`:quicknet`, `:default`) now try several official mirrors transparently. If one endpoint returns 5xx, times out, or fails to connect, the next one is tried. 4xx responses (like 404 for a non-existent round) are returned immediately without retrying.

Draw and round results now include a `served_by` key with the endpoint that actually responded.

`Drand::Chain.new` accepts either `base_url:` (single endpoint) or `endpoints:` (list). Custom chains still default to one endpoint. `Chain#base_url` is kept as a shortcut for `endpoints.first`.

## 0.1.1

Add source code, bug tracker, and changelog links to gem metadata so they show up on rubygems.org.

## 0.1.0

Initial release. Round math for quicknet and the default mainnet, plus HTTP fetch of round values.
