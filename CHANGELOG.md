# Changelog

## 0.2.0

Known chains (`:quicknet`, `:default`) now try several official mirrors transparently. If one endpoint returns 5xx, times out, or fails to connect, the next one is tried. 4xx responses (like 404 for a non-existent round) are returned immediately without retrying.

Draw and round results now include a `served_by` key with the endpoint that actually responded.

`Drand::Chain.new` accepts either `base_url:` (single endpoint) or `endpoints:` (list). Custom chains still default to one endpoint. `Chain#base_url` is kept as a shortcut for `endpoints.first`.

## 0.1.1

Add source code, bug tracker, and changelog links to gem metadata so they show up on rubygems.org.

## 0.1.0

Initial release. Round math for quicknet and the default mainnet, plus HTTP fetch of round values.
