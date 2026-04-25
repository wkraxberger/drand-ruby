# frozen_string_literal: true

RSpec.describe Drand::Verifier do
  describe "quicknet (bls-unchained-g1-rfc9380)" do
    let(:public_key) do
      "83cf0f2896adee7eb8b5f01fcad3912212c437e0073e911fb90022d3e760183c" \
      "8c4b450b6a0a6c3ac6a5776a2d1064510d1fec758c921cc22b0e17e63aaf4bcb" \
      "5ed66304de9cf809bd274ca73bab4af5a6e9c76a4bc09e76eae8991ef5ece45a"
    end

    # Captured from https://api.drand.sh/<quicknet-hash>/public/1000
    let(:round) { 1000 }
    let(:signature) do
      "b44679b9a59af2ec876b1a6b1ad52ea9b1615fc3982b19576350f93447cb1125" \
      "e342b73a8dd2bacbe47e4b6b63ed5e39"
    end

    it "verifies a real signed round" do
      ok = described_class.verify(
        scheme: Drand::Verifier::UNCHAINED_G1,
        public_key: public_key,
        round: round,
        signature: signature
      )
      expect(ok).to be(true)
    end

    it "rejects a tampered round" do
      ok = described_class.verify(
        scheme: Drand::Verifier::UNCHAINED_G1,
        public_key: public_key,
        round: round + 1,
        signature: signature
      )
      expect(ok).to be(false)
    end
  end

  describe "default mainnet (pedersen-bls-chained)" do
    let(:public_key) do
      "868f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a5699" \
      "37c529eeda66c7293784a9402801af31"
    end

    # Captured from https://api.drand.sh/<default-hash>/public/1000
    let(:round) { 1000 }
    let(:signature) do
      "99bf96de133c3d3937293cfca10c8152b18ab2d034ccecf115658db324d2edc0" \
      "0a16a2044cd04a8a38e2a307e5ecff3511315be8d282079faf24098f283e0ed2" \
      "c199663b334d2e84c55c032fe469b212c5c2087ebb83a5b25155c3283f5b79ac"
    end
    let(:previous_signature) do
      "af0d93299a363735fe847f5ea241442c65843dc1bd3a7b79646b3b10072e908b" \
      "f034d35cd69d378e3341f139100cd4cd03030399864ef8803a5a4f5e64fccc20" \
      "bbae36d1ca22a6ddc43d2630c41105e90598fab11e5c7456df3925d4b577b113"
    end

    it "verifies a real signed round" do
      ok = described_class.verify(
        scheme: Drand::Verifier::CHAINED_G2,
        public_key: public_key,
        round: round,
        signature: signature,
        previous_signature: previous_signature
      )
      expect(ok).to be(true)
    end

    it "raises if previous_signature is missing" do
      expect {
        described_class.verify(
          scheme: Drand::Verifier::CHAINED_G2,
          public_key: public_key,
          round: round,
          signature: signature
        )
      }.to raise_error(Drand::VerificationError, /previous_signature/)
    end
  end

  describe "errors" do
    it "raises on unsupported scheme" do
      expect {
        described_class.verify(scheme: "made-up", public_key: "ab", round: 1, signature: "ab")
      }.to raise_error(Drand::VerificationError, /unsupported scheme/)
    end

    it "raises on missing public_key" do
      expect {
        described_class.verify(scheme: Drand::Verifier::UNCHAINED_G1, public_key: "", round: 1, signature: "ab")
      }.to raise_error(Drand::VerificationError)
    end

    it "raises on non-positive round" do
      expect {
        described_class.verify(scheme: Drand::Verifier::UNCHAINED_G1, public_key: "ab", round: 0, signature: "ab")
      }.to raise_error(Drand::VerificationError)
    end
  end
end
