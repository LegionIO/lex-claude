# frozen_string_literal: true

require 'legion/extensions/claude/client'

RSpec.describe Legion::Extensions::Claude::Client do
  let(:api_key) { 'test-api-key' }
  let(:client) { described_class.new(api_key: api_key) }
  let(:faraday_conn) { instance_double(Faraday::Connection) }

  before do
    allow(Faraday).to receive(:new).and_return(faraday_conn)
  end

  it 'stores config on initialization' do
    expect(client.config[:api_key]).to eq(api_key)
    expect(client.config[:host]).to eq(Legion::Extensions::Claude::Helpers::Client::DEFAULT_HOST)
  end

  it 'responds to message runner methods' do
    expect(client).to respond_to(:create)
    expect(client).to respond_to(:count_tokens)
  end

  it 'responds to model runner methods' do
    expect(client).to respond_to(:list)
    expect(client).to respond_to(:retrieve)
  end

  it 'responds to batch runner methods' do
    expect(client).to respond_to(:create_batch)
    expect(client).to respond_to(:list_batches)
    expect(client).to respond_to(:retrieve_batch)
    expect(client).to respond_to(:cancel_batch)
    expect(client).to respond_to(:batch_results)
  end
end
