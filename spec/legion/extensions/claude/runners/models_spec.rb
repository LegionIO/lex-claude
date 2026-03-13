# frozen_string_literal: true

RSpec.describe Legion::Extensions::Claude::Runners::Models do
  let(:test_class) do
    Class.new do
      include Legion::Extensions::Claude::Runners::Models

      def client(**)
        Legion::Extensions::Claude::Helpers::Client.client(**)
      end
    end
  end
  let(:instance) { test_class.new }
  let(:api_key) { 'test-api-key' }

  let(:faraday_conn) { instance_double(Faraday::Connection) }

  before do
    allow(Faraday).to receive(:new).and_return(faraday_conn)
  end

  describe '#list' do
    let(:list_response) do
      instance_double(Faraday::Response, body: {
                        'data'     => [
                          { 'id' => 'claude-sonnet-4-20250514', 'type' => 'model' },
                          { 'id' => 'claude-haiku-4-20250414', 'type' => 'model' }
                        ],
                        'has_more' => false
                      }, status: 200)
    end

    it 'lists available models' do
      allow(faraday_conn).to receive(:get).with('/v1/models', hash_including(limit: 20)).and_return(list_response)

      result = instance.list(api_key: api_key)

      expect(result[:status]).to eq(200)
      expect(result[:result]['data'].length).to eq(2)
    end

    it 'supports pagination parameters' do
      allow(faraday_conn).to receive(:get).with('/v1/models', hash_including(limit: 5, after_id: 'abc')).and_return(list_response)

      result = instance.list(api_key: api_key, limit: 5, after_id: 'abc')

      expect(result[:status]).to eq(200)
    end
  end

  describe '#retrieve' do
    let(:model_response) do
      instance_double(Faraday::Response, body: {
                        'id'           => 'claude-sonnet-4-20250514',
                        'type'         => 'model',
                        'display_name' => 'Claude Sonnet 4'
                      }, status: 200)
    end

    it 'retrieves a specific model' do
      allow(faraday_conn).to receive(:get).with('/v1/models/claude-sonnet-4-20250514').and_return(model_response)

      result = instance.retrieve(api_key: api_key, model_id: 'claude-sonnet-4-20250514')

      expect(result[:status]).to eq(200)
      expect(result[:result]['id']).to eq('claude-sonnet-4-20250514')
    end
  end
end
