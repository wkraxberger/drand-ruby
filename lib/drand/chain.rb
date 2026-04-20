# frozen_string_literal: true

require "date"
require "time"

require_relative "errors"
require_relative "http_client"

module Drand
  class Chain
    DEFAULT_BASE_URL = "https://api.drand.sh"

    attr_reader :chain_hash, :period, :base_url

    def initialize(chain_hash:, genesis_time:, period:, base_url: DEFAULT_BASE_URL)
      raise ArgumentError, "chain_hash required" if chain_hash.nil? || chain_hash.empty?
      raise ArgumentError, "genesis_time must be an Integer" unless genesis_time.is_a?(Integer)
      raise ArgumentError, "period must be a positive Integer" unless period.is_a?(Integer) && period.positive?

      @chain_hash = chain_hash
      @genesis_unix = genesis_time
      @period = period
      @base_url = base_url
      @http = HttpClient.new(base_url: base_url, chain_hash: chain_hash)
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

    private

    def to_utc(time)
      case time
      when Time then time.getutc
      when DateTime then time.to_time.getutc
      else
        raise ArgumentError, "expected Time or DateTime" unless time.respond_to?(:to_time)
        time.to_time.getutc
      end
    end
  end
end
