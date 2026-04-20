# frozen_string_literal: true

RSpec.describe Drand::Chain do
  let(:chain) { Drand::Chain.new(chain_hash: "abc", genesis_time: 1_000_000, period: 10) }

  describe "#round_at" do
    it "returns 1 at genesis" do
      expect(chain.round_at(Time.at(1_000_000).utc)).to eq(1)
    end

    it "advances one round per period" do
      expect(chain.round_at(Time.at(1_000_010).utc)).to eq(2)
      expect(chain.round_at(Time.at(1_000_100).utc)).to eq(11)
    end

    it "stays in the current round for sub-period offsets" do
      expect(chain.round_at(Time.at(1_000_009.9).utc)).to eq(1)
    end

    it "raises RoundError before genesis" do
      expect { chain.round_at(Time.at(999_999).utc) }.to raise_error(Drand::RoundError)
    end

    it "accepts DateTime" do
      expect(chain.round_at(Time.at(1_000_010).utc.to_datetime)).to eq(2)
    end

    it "rejects non-time input" do
      expect { chain.round_at("2026-01-01") }.to raise_error(Drand::ArgumentError)
    end
  end

  describe "#time_of" do
    it "returns genesis for round 1" do
      expect(chain.time_of(1)).to eq(Time.at(1_000_000).utc)
    end

    it "raises for round 0 or negative" do
      expect { chain.time_of(0) }.to raise_error(Drand::RoundError)
      expect { chain.time_of(-1) }.to raise_error(Drand::RoundError)
    end
  end

  describe "round math roundtrip" do
    it "time_of(round_at(t)) <= t for several sample times" do
      [0, 1, 10, 99, 100, 12_345, 1_000_000].each do |offset|
        t = Time.at(1_000_000 + offset).utc
        r = chain.round_at(t)
        expect(chain.time_of(r)).to be <= t
      end
    end
  end

  describe "well-known chains" do
    it "computes round numbers for quicknet" do
      q = Drand.chain(:quicknet)
      t = Time.utc(2026, 4, 20)
      expect(q.round_at(t)).to eq(((t.to_i - 1_692_803_367) / 3) + 1)
    end

    it "computes round numbers for default mainnet" do
      m = Drand.chain(:default)
      t = Time.utc(2026, 4, 20)
      expect(m.round_at(t)).to eq(((t.to_i - 1_595_431_050) / 30) + 1)
    end
  end

  describe "#round" do
    let(:hash) { "52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971" }
    let(:q) { Drand.chain(:quicknet) }

    it "fetches a past round from the API" do
      stub_request(:get, "https://api.drand.sh/#{hash}/public/42")
        .to_return(status: 200, body: { round: 42, randomness: "aa", signature: "bb" }.to_json)

      result = q.round(42)
      expect(result).to include(round: 42, randomness: "aa", signature: "bb", verified: false)
    end

    it "raises RoundError for future rounds" do
      expect { q.round(q.current_round + 10_000) }.to raise_error(Drand::RoundError, /future/)
    end

    it "raises RoundError for round 0" do
      expect { q.round(0) }.to raise_error(Drand::RoundError)
    end
  end
end
