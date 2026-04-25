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

    it "stays in the current round for sub period offsets" do
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
    let(:q) { Drand.chain(:quicknet, base_url: "https://api.drand.sh") }

    it "fetches a past round from the api" do
      stub_request(:get, "https://api.drand.sh/#{hash}/public/42")
        .to_return(status: 200, body: { round: 42, randomness: "aa", signature: "bb" }.to_json)

      result = q.round(42, verify: false)
      expect(result).to include(round: 42, randomness: "aa", signature: "bb", verified: false)
      expect(result[:served_by]).to eq("https://api.drand.sh")
    end

    it "raises RoundError for future rounds" do
      expect { q.round(q.current_round + 10_000, verify: false) }.to raise_error(Drand::RoundError, /future/)
    end

    it "raises RoundError for round 0" do
      expect { q.round(0, verify: false) }.to raise_error(Drand::RoundError)
    end

    it "verifies a real signed round on quicknet by default" do
      sig = "b44679b9a59af2ec876b1a6b1ad52ea9b1615fc3982b19576350f93447cb1125e342b73a8dd2bacbe47e4b6b63ed5e39"
      stub_request(:get, "https://api.drand.sh/#{hash}/public/1000")
        .to_return(status: 200, body: { round: 1000, randomness: "fe290beca10872ef2fb164d2aa4442de4566183ec51c56ff3cd603d930e54fdd", signature: sig }.to_json)

      result = q.round(1000)
      expect(result[:verified]).to be(true)
    end

    it "raises VerificationError when the signature is bogus and verify is on" do
      stub_request(:get, "https://api.drand.sh/#{hash}/public/77")
        .to_return(status: 200, body: { round: 77, randomness: "aa", signature: "bb" }.to_json)

      expect { q.round(77) }.to raise_error(Drand::VerificationError)
    end
  end

  describe "#draw" do
    let(:hash) { "52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971" }
    let(:q) { Drand.chain(:quicknet, base_url: "https://api.drand.sh") }

    it "is deterministic for the same round and range" do
      stub_request(:get, "https://api.drand.sh/#{hash}/public/200")
        .to_return(status: 200, body: { round: 200, randomness: "thisissorandomomg", signature: "*" }.to_json)

      a = q.draw(1..1_000_000, round: 200, verify: false)[:value]
      b = q.draw(1..1_000_000, round: 200, verify: false)[:value]
      expect(a).to eq(b)
    end

    it "rejects empty ranges" do
      stub_request(:get, "https://api.drand.sh/#{hash}/public/201")
        .to_return(status: 200, body: { round: 201, randomness: "thisisreallyreallyrandom", signature: "*" }.to_json)

      expect { q.draw(5..1, round: 201, verify: false) }.to raise_error(Drand::ArgumentError)
    end

    it "falls back to a mirror when the first endpoint returns 502" do
      chain = Drand.chain(:quicknet, endpoints: ["https://m1.example", "https://m2.example"])
      stub_request(:get, "https://m1.example/#{hash}/public/300").to_return(status: 502)
      stub_request(:get, "https://m2.example/#{hash}/public/300")
        .to_return(status: 200, body: { round: 300, randomness: "thisissorandomomg", signature: "*" }.to_json)

      result = chain.draw(1..100, round: 300, verify: false)
      expect(result[:value]).to be_between(1, 100)
      expect(result[:served_by]).to eq("https://m2.example")
    end
  end
end
