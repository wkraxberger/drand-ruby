# frozen_string_literal: true

module Drand
  class Error < StandardError; end
  class ArgumentError < Error; end
  class RoundError < Error; end

  class NetworkError < Error
    attr_reader :status

    def initialize(message, status: nil)
      super(message)
      @status = status
    end
  end
end
