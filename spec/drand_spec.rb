# frozen_string_literal: true

RSpec.describe Drand do
  it "returns a quicknet chain" do
    c = Drand.chain(:quicknet)
    expect(c.period).to eq(3)
    expect(c.genesis_time).to eq(Time.at(1_692_803_367).utc)
  end

  it "returns a default mainnet chain" do
    c = Drand.chain(:default)
    expect(c.period).to eq(30)
  end

  it "defaults to quicknet" do
    expect(Drand.chain.chain_hash).to eq(Drand.chain(:quicknet).chain_hash)
  end

  it "raises on unknown chain names" do
    expect { Drand.chain(:foo) }.to raise_error(Drand::ArgumentError)
  end

  it "labels a known chain by name and a custom one as 'custom'" do
    expect(Drand.chain(:quicknet).name).to eq("quicknet")
    custom = Drand::Chain.new(chain_hash: "abc", genesis_time: 1, period: 3)
    expect(custom.name).to eq("custom")
  end
end
