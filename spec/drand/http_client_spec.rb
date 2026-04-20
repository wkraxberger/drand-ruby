# frozen_string_literal: true

RSpec.describe Drand::HttpClient do
  let(:client) { described_class.new(base_url: "https://api.drand.example", chain_hash: "xyz") }
  let(:url) { "https://api.drand.example/xyz/public/7" }

  it "parses a successful response" do
    stub_request(:get, url).to_return(
      status: 200,
      body: { round: 7, randomness: "r", signature: "s", previous_signature: "p" }.to_json
    )

    expect(client.fetch_round(7)).to eq(
      round: 7, randomness: "r", signature: "s", previous_signature: "p"
    )
  end

  it "tolerates a missing previous_signature" do
    stub_request(:get, url).to_return(status: 200, body: { round: 7, randomness: "r", signature: "s" }.to_json)
    expect(client.fetch_round(7)[:previous_signature]).to be_nil
  end

  it "raises NetworkError on HTTP error" do
    stub_request(:get, url).to_return(status: 404)
    expect { client.fetch_round(7) }.to raise_error(Drand::NetworkError, /404/)
  end

  it "raises NetworkError on connection failure" do
    stub_request(:get, url).to_raise(SocketError.new("no DNS"))
    expect { client.fetch_round(7) }.to raise_error(Drand::NetworkError)
  end

  it "raises NetworkError on bad JSON" do
    stub_request(:get, url).to_return(status: 200, body: "<html>nope</html>")
    expect { client.fetch_round(7) }.to raise_error(Drand::NetworkError, /JSON/)
  end
end
