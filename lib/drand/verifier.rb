# frozen_string_literal: true

require "bls"
require "digest"

require_relative "errors"

module Drand
  module Verifier
    UNCHAINED_G1 = "bls-unchained-g1-rfc9380"
    CHAINED_G2   = "pedersen-bls-chained"

    SUPPORTED_SCHEMES = [UNCHAINED_G1, CHAINED_G2].freeze

    module_function

    def verify(scheme:, public_key:, round:, signature:, previous_signature: nil)
      raise VerificationError, "scheme is required" if scheme.nil? || scheme.empty?
      raise VerificationError, "public_key is required" if public_key.nil? || public_key.empty?
      raise VerificationError, "signature is required" if signature.nil? || signature.empty?
      raise VerificationError, "round must be a positive Integer" unless round.is_a?(Integer) && round.positive?

      case scheme
      when UNCHAINED_G1
        verify_unchained_g1(public_key, round, signature)
      when CHAINED_G2
        verify_chained_g2(public_key, round, signature, previous_signature)
      else
        raise VerificationError, "unsupported scheme #{scheme.inspect}"
      end
    rescue BLS::Error, BLS::PointError => e
      raise VerificationError, "BLS error: #{e.message}"
    rescue ::ArgumentError => e
      raise VerificationError, "invalid hex input: #{e.message}"
    end

    def verify_unchained_g1(public_key_hex, round, signature_hex)
      msg = Digest::SHA256.hexdigest(round_bytes(round))
      sig = BLS::PointG1.from_hex(signature_hex)
      pk  = BLS::PointG2.from_hex(public_key_hex)
      BLS.verify(sig, msg, pk)
    end

    def verify_chained_g2(public_key_hex, round, signature_hex, previous_signature_hex)
      if previous_signature_hex.nil? || previous_signature_hex.empty?
        raise VerificationError, "chained scheme requires previous_signature"
      end
      prev_bytes = [previous_signature_hex].pack("H*")
      msg = Digest::SHA256.hexdigest(prev_bytes + round_bytes(round))
      sig = BLS::PointG2.from_hex(signature_hex)
      pk  = BLS::PointG1.from_hex(public_key_hex)
      BLS.verify(sig, msg, pk)
    end

    def round_bytes(round)
      [round].pack("Q>")
    end
  end
end
