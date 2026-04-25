# frozen_string_literal: true

require_relative "drand/version"
require_relative "drand/errors"
require_relative "drand/http_client"
require_relative "drand/verifier"
require_relative "drand/chain"

module Drand
  OFFICIAL_ENDPOINTS = [
    "https://api.drand.sh",
    "https://api2.drand.sh",
    "https://api3.drand.sh",
    "https://drand.cloudflare.com"
  ].freeze

  CHAINS = {
    quicknet: {
      chain_hash: "52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971",
      genesis_time: 1_692_803_367,
      period: 3,
      endpoints: OFFICIAL_ENDPOINTS,
      scheme: Verifier::UNCHAINED_G1,
      public_key: "83cf0f2896adee7eb8b5f01fcad3912212c437e0073e911fb90022d3e760183c" \
                  "8c4b450b6a0a6c3ac6a5776a2d1064510d1fec758c921cc22b0e17e63aaf4bcb" \
                  "5ed66304de9cf809bd274ca73bab4af5a6e9c76a4bc09e76eae8991ef5ece45a"
    },
    default: {
      chain_hash: "8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce",
      genesis_time: 1_595_431_050,
      period: 30,
      endpoints: OFFICIAL_ENDPOINTS,
      scheme: Verifier::CHAINED_G2,
      public_key: "868f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a5699" \
                  "37c529eeda66c7293784a9402801af31"
    }
  }.freeze

  def self.chain(name = :quicknet, base_url: nil, endpoints: nil)
    config = CHAINS[name.to_sym]
    raise ArgumentError, "unknown chain #{name.inspect}" unless config

    final_endpoints =
      if endpoints
        Array(endpoints)
      elsif base_url
        [base_url]
      else
        config[:endpoints]
      end

    Chain.new(
      chain_hash: config[:chain_hash],
      genesis_time: config[:genesis_time],
      period: config[:period],
      endpoints: final_endpoints,
      name: name.to_s,
      scheme: config[:scheme],
      public_key: config[:public_key]
    )
  end
end
