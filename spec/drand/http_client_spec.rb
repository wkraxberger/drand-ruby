# frozen_string_literal: true

RSpec.describe Drand::HttpClient do
  let(:single) { described_class.new(endpoints: ["https://api.drand.example"], chain_hash: "xyz") }
  let(:url) { "https://api.drand.example/xyz/public/7" }

  it "parses a successful response" do
    stub_request(:get, url).to_return(
      status: 200,
      body: { round: 7, randomness: "r", signature: "s", previous_signature: "p" }.to_json
    )

    result = single.fetch_round(7)
    expect(result).to include(round: 7, randomness: "r", signature: "s", previous_signature: "p")
    expect(result[:served_by]).to eq("https://api.drand.example")
  end

  it "tolerates a missing previous_signature" do
    stub_request(:get, url).to_return(status: 200, body: { round: 7, randomness: "r", signature: "s" }.to_json)
    expect(single.fetch_round(7)[:previous_signature]).to be_nil
  end

  it "raises NetworkError on a 4xx and does not try other endpoints" do
    stub_request(:get, url).to_return(status: 404)
    expect { single.fetch_round(7) }.to raise_error(Drand::NetworkError, /404/)
  end

  it "raises NetworkError on connection failure" do
    stub_request(:get, url).to_raise(SocketError.new("no DNS"))
    expect { single.fetch_round(7) }.to raise_error(Drand::NetworkError)
  end

  it "raises NetworkError on bad JSON" do
    stub_request(:get, url).to_return(status: 200, body: "<html>nope</html>")
    expect { single.fetch_round(7) }.to raise_error(Drand::NetworkError, /JSON/)
  end

  describe "with multiple endpoints" do
    let(:client) do
      described_class.new(
        endpoints: ["https://a.example", "https://b.example", "https://c.example"],
        chain_hash: "xyz"
      )
    end

    it "returns the first endpoint's response on success" do
      stub_request(:get, "https://a.example/xyz/public/7")
        .to_return(status: 200, body: { round: 7, randomness: "r", signature: "s" }.to_json)

      expect(client.fetch_round(7)[:served_by]).to eq("https://a.example")
    end

    it "falls back to the next endpoint on 5xx" do
      stub_request(:get, "https://a.example/xyz/public/7").to_return(status: 502)
      stub_request(:get, "https://b.example/xyz/public/7")
        .to_return(status: 200, body: { round: 7, randomness: "r", signature: "s" }.to_json)

      expect(client.fetch_round(7)[:served_by]).to eq("https://b.example")
    end

    it "falls back on timeouts and connection errors" do
      stub_request(:get, "https://a.example/xyz/public/7").to_timeout
      stub_request(:get, "https://b.example/xyz/public/7").to_raise(SocketError.new("nope"))
      stub_request(:get, "https://c.example/xyz/public/7")
        .to_return(status: 200, body: { round: 7, randomness: "r", signature: "s" }.to_json)

      expect(client.fetch_round(7)[:served_by]).to eq("https://c.example")
    end

    it "does NOT fall back on 4xx" do
      stub_request(:get, "https://a.example/xyz/public/7").to_return(status: 404)
      expect { client.fetch_round(7) }.to raise_error(Drand::NetworkError, /404/)
      expect(WebMock).not_to have_requested(:get, "https://b.example/xyz/public/7")
    end

    it "raises with all failures when every endpoint fails" do
      stub_request(:get, "https://a.example/xyz/public/7").to_return(status: 502)
      stub_request(:get, "https://b.example/xyz/public/7").to_return(status: 503)
      stub_request(:get, "https://c.example/xyz/public/7").to_return(status: 504)

      expect { client.fetch_round(7) }.to raise_error(Drand::NetworkError, /all endpoints failed/)
    end
  end

  it "rejects construction with no endpoints" do
    expect {
      described_class.new(endpoints: [], chain_hash: "xyz")
    }.to raise_error(Drand::ArgumentError)
  end
end
