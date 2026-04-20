# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "errors"

module Drand
  class HttpClient
    def initialize(base_url:, chain_hash:)
      @base_url = base_url.to_s.chomp("/")
      @chain_hash = chain_hash
    end

    def fetch_round(number)
      uri = URI("#{@base_url}/#{@chain_hash}/public/#{number}")
      body = get(uri)
      data = JSON.parse(body)

      {
        round: Integer(data.fetch("round")),
        randomness: data.fetch("randomness"),
        signature: data.fetch("signature"),
        previous_signature: data["previous_signature"]
      }
    rescue JSON::ParserError => e
      raise NetworkError, "bad JSON: #{e.message}"
    rescue KeyError => e
      raise NetworkError, "missing field: #{e.message}"
    end

    private

    def get(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 5
      http.read_timeout = 10

      res = http.get(uri.request_uri)
      raise NetworkError, "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      res.body
    rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise NetworkError, "#{e.class}: #{e.message}"
    end
  end
end
