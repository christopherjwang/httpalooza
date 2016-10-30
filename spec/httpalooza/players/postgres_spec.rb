require 'spec_helper'

describe HTTPalooza::Players::PostgresPlayer do

  before (:each) do
    `which postgres`

    unless $? == 0
      skip('`postgres` is not installed; skipping tests')
    end

    begin
      unless http_extension_installed?
        skip('http extension is not installed; skipping tests')
      end
    rescue PG::ConnectionBad => e
      skip("issue connecting to database #{HTTPalooza::Players::PostgresPlayer::DATABASE_NAME}; skipping tests. error: #{e.error}")
    end

  end

  describe '#get' do
    it 'supports 200s' do
      response = make_request(:get, 'http://httpbin.org/get?httpalooza=true')
      expect(response.code).to eq(200)
      expect(JSON.load(response.body)['args']).to eq('httpalooza' => 'true')
    end

    it 'supports 200s with hash payload' do
      response = make_request(:get, 'http://httpbin.org/get', :payload => { :httpalooza => true })
      expect(response.code).to eq(200)
      expect(JSON.load(response.body)['args']).to eq('httpalooza' => 'true')
    end

    it 'follows 301s' do
      response = make_request(:get, 'http://httpbin.org/status/301')
      expect(response.code).to eq(200)
      expect(response.body).to include('http://httpbin.org/get')
    end
  end

  describe '#post' do
    it 'supports 200s with hash payload' do
      response = make_request(:post, 'http://httpbin.org/post', :payload => { :httpalooza => true })
      expect(response.code).to eq(200)
      expect(JSON.load(response.body)['form']).to eq({'httpalooza' => 'true'})
    end

    it 'supports 200s with json payload' do
      response = make_request(:post, 'http://httpbin.org/post', :payload => '{ "httpalooza": true }')
      expect(response.code).to eq(200)
      expect(JSON.load(response.body)['form']).to eq({'httpalooza' => 'true'})
    end
  end

  def make_request(method, url, options = {})
    HTTPalooza.invite.i_guess_postgres_can_come_too.public_send(method, url, options)[:postgres]
  end

  def http_extension_installed?
    result = PG.connect(:dbname => HTTPalooza::Players::PostgresPlayer::DATABASE_NAME).exec("SELECT COUNT(*) FROM pg_extension WHERE extname = 'http'")
    result.first['count'].to_i >= 1
  end
end
