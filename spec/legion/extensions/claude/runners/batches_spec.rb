# frozen_string_literal: true

RSpec.describe Legion::Extensions::Claude::Runners::Batches do
  let(:test_class) do
    Class.new do
      include Legion::Extensions::Claude::Runners::Batches

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

  let(:batch_response) do
    instance_double(Faraday::Response, body: {
                      'id'                => 'batch_123',
                      'type'              => 'message_batch',
                      'processing_status' => 'in_progress'
                    }, status: 200)
  end

  describe '#create_batch' do
    it 'creates a message batch' do
      requests = [
        { custom_id: 'req-1', params: { model: 'claude-sonnet-4-20250514', max_tokens: 100,
                                        messages: [{ role: 'user', content: 'Hi' }] } }
      ]
      allow(faraday_conn).to receive(:post).with('/v1/messages/batches', hash_including(requests: requests)).and_return(batch_response)

      result = instance.create_batch(api_key: api_key, requests: requests)

      expect(result[:status]).to eq(200)
      expect(result[:result]['id']).to eq('batch_123')
    end
  end

  describe '#list_batches' do
    let(:list_response) do
      instance_double(Faraday::Response, body: {
                        'data'     => [{ 'id' => 'batch_123' }],
                        'has_more' => false
                      }, status: 200)
    end

    it 'lists message batches' do
      allow(faraday_conn).to receive(:get).with('/v1/messages/batches', hash_including(limit: 20)).and_return(list_response)

      result = instance.list_batches(api_key: api_key)

      expect(result[:status]).to eq(200)
      expect(result[:result]['data'].length).to eq(1)
    end
  end

  describe '#retrieve_batch' do
    it 'retrieves a specific batch' do
      allow(faraday_conn).to receive(:get).with('/v1/messages/batches/batch_123').and_return(batch_response)

      result = instance.retrieve_batch(api_key: api_key, batch_id: 'batch_123')

      expect(result[:status]).to eq(200)
      expect(result[:result]['processing_status']).to eq('in_progress')
    end
  end

  describe '#cancel_batch' do
    it 'cancels a batch' do
      cancel_response = instance_double(Faraday::Response, body: {
                                          'id'                => 'batch_123',
                                          'processing_status' => 'canceling'
                                        }, status: 200)
      allow(faraday_conn).to receive(:post).with('/v1/messages/batches/batch_123/cancel').and_return(cancel_response)

      result = instance.cancel_batch(api_key: api_key, batch_id: 'batch_123')

      expect(result[:status]).to eq(200)
      expect(result[:result]['processing_status']).to eq('canceling')
    end
  end

  describe '#batch_results' do
    it 'retrieves batch results' do
      results_response = instance_double(Faraday::Response, body: [
                                           { 'custom_id' => 'req-1', 'result' => { 'type' => 'succeeded' } }
                                         ], status: 200)
      allow(faraday_conn).to receive(:get).with('/v1/messages/batches/batch_123/results').and_return(results_response)

      result = instance.batch_results(api_key: api_key, batch_id: 'batch_123')

      expect(result[:status]).to eq(200)
      expect(result[:result].first['custom_id']).to eq('req-1')
    end
  end
end
