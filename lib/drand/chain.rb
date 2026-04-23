# frozen_string_literal: true

require "date"
require "digest"
require "time"

require_relative "errors"
require_relative "http_client"

module Drand
  class Chain
    DEFAULT_ENDPOINTS = ["https://api.drand.sh"].freeze

    attr_reader :chain_hash, :period, :endpoints, :name

    def initialize(chain_hash:, genesis_time:, period:, base_url: nil, endpoints: nil, name: "custom")
      raise ArgumentError, "chain_hash required" if chain_hash.nil? || chain_hash.empty?
      raise ArgumentError, "genesis_time must be an Integer" unless genesis_time.is_a?(Integer)
      raise ArgumentError, "period must be a positive Integer" unless period.is_a?(Integer) && period.positive?

      @chain_hash = chain_hash
      @genesis_unix = genesis_time
      @period = period
      @name = name
      @endpoints = resolve_endpoints(base_url, endpoints)
      @http = HttpClient.new(endpoints: @endpoints, chain_hash: chain_hash)
    end

    # Kept for backward compatibility; returns the first endpoint.
    def base_url
      @endpoints.first
    end

    def genesis_time
      Time.at(@genesis_unix).utc
    end

    def round_at(time)
      t = to_utc(time)
      elapsed = t.to_r - @genesis_unix
      raise RoundError, "time is before chain genesis" if elapsed.negative?
      (elapsed / @period).floor + 1
    end

    def time_of(round)
      raise ArgumentError, "round must be an Integer" unless round.is_a?(Integer)
      raise RoundError, "round must be >= 1" if round < 1
      Time.at(@genesis_unix + (round - 1) * @period).utc
    end

    def current_round
      round_at(Time.now.utc)
    end

    def round(number)
      raise ArgumentError, "round must be an Integer" unless number.is_a?(Integer)
      raise RoundError, "round must be >= 1" if number < 1
      raise RoundError, "round #{number} is in the future" if number > current_round

      @http.fetch_round(number).merge(verified: false)
    end

    def draw(range, round: current_round)
      lo, hi = normalize_range(range)
      data = self.round(round)
      {
        value: sample_in(data[:randomness], lo, hi),
        range: { min: lo, max: hi },
        round: data[:round],
        chain: @name,
        chain_hash: @chain_hash,
        randomness: data[:randomness],
        signature: data[:signature],
        verified: false,
        served_by: data[:served_by]
      }
    end

    private

    def resolve_endpoints(base_url, endpoints)
      if base_url && endpoints
        raise ArgumentError, "pass either base_url: or endpoints:, not both"
      end
      list =
        if endpoints
          Array(endpoints)
        elsif base_url
          [base_url]
        else
          DEFAULT_ENDPOINTS
        end
      list.map { |u| u.to_s }.freeze
    end

    def to_utc(time)
      case time
      when Time then time.getutc
      when DateTime then time.to_time.getutc
      else
        raise ArgumentError, "expected Time or DateTime" unless time.respond_to?(:to_time)
        time.to_time.getutc
      end
    end

    def normalize_range(range)
      raise ArgumentError, "range must be a Range" unless range.is_a?(::Range)
      lo = range.begin
      hi = range.end
      raise ArgumentError, "range needs integer bounds" unless lo.is_a?(Integer) && hi.is_a?(Integer)
      hi -= 1 if range.exclude_end?
      raise ArgumentError, "range is invalid" if hi <= lo
      [lo, hi]
    end

    # Unbiased integer in [lo, hi], via rejection sampling over a SHA256 byte stream.
    def sample_in(randomness, lo, hi)
      n = hi - lo + 1
      width = (n.bit_length + 32).ceildiv(8)
      space = 1 << (width * 8)
      cutoff = space - (space % n)

      buf = String.new(encoding: Encoding::BINARY)
      counter = 0
      loop do
        while buf.bytesize < width
          buf << Digest::SHA256.digest(randomness + counter.to_s)
          counter += 1
        end
        v = buf.byteslice(0, width).unpack1("H*").to_i(16)
        buf = buf.byteslice(width..)
        return lo + (v % n) if v < cutoff
      end
    end
  end
end
