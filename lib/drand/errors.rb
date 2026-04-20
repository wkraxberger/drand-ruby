# frozen_string_literal: true

module Drand
  class Error < StandardError; end
  class ArgumentError < Error; end
  class NetworkError < Error; end
  class RoundError < Error; end
end
