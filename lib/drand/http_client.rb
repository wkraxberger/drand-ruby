# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "errors"

module Drand
  class HttpClient
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 3

    RETRYABLE_NETWORK_ERRORS = [
      SocketError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      IOError
    ].freeze

    def initialize(endpoints:, chain_hash:)
      list = Array(endpoints).map { |u| u.to_s.chomp("/") }
      raise ArgumentError, "at least one endpoint is required" if list.empty?

      @endpoints = list
      @chain_hash = chain_hash
    end

    def fetch_round(number)
      body, served_by = fetch_with_fallback("/#{@chain_hash}/public/#{number}")
      data = JSON.parse(body)

      {
        round: Integer(data.fetch("round")),
        randomness: data.fetch("randomness"),
        signature: data.fetch("signature"),
        previous_signature: data["previous_signature"],
        served_by: served_by
      }
    rescue JSON::ParserError => e
      raise NetworkError, "malformed JSON from drand: #{e.message}"
    rescue KeyError => e
      raise NetworkError, "missing field in drand response: #{e.message}"
    end

    private

    def fetch_with_fallback(path)
      attempts = []
      @endpoints.each do |endpoint|
        begin
          return [http_get(URI("#{endpoint}#{path}")), endpoint]
        rescue NetworkError => e
          # 4xx is final: the round doesn't exist or the request is malformed.
          raise if e.status && (400..499).cover?(e.status)
          attempts << "#{endpoint}: #{e.message}"
        end
      end
      raise NetworkError.new("all endpoints failed for #{path}: #{attempts.join("; ")}")
    end

    def http_get(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      res = http.get(uri.request_uri)
      unless res.is_a?(Net::HTTPSuccess)
        raise NetworkError.new("HTTP #{res.code}", status: res.code.to_i)
      end
      res.body
    rescue *RETRYABLE_NETWORK_ERRORS => e
      raise NetworkError.new("#{e.class}: #{e.message}")
    end
  end
end
