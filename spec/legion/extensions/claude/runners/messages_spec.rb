# frozen_string_literal: true

RSpec.describe Legion::Extensions::Claude::Runners::Messages do
  let(:test_class) do
    Class.new do
      include Legion::Extensions::Claude::Runners::Messages

      def client(**)
        Legion::Extensions::Claude::Helpers::Client.client(**)
      end
    end
  end
  let(:instance) { test_class.new }
  let(:api_key) { 'test-api-key' }
  let(:model) { 'claude-sonnet-4-20250514' }
  let(:messages) { [{ role: 'user', content: 'Hello' }] }

  let(:success_response) do
    instance_double(Faraday::Response, body: {
                      'id'      => 'msg_123',
                      'type'    => 'message',
                      'role'    => 'assistant',
                      'content' => [{ 'type' => 'text', 'text' => 'Hello!' }],
                      'model'   => model
                    }, status: 200, headers: {})
  end

  let(:faraday_conn) { instance_double(Faraday::Connection) }

  before do
    allow(Faraday).to receive(:new).and_return(faraday_conn)
  end

  describe '#create' do
    it 'sends a message creation request' do
      allow(faraday_conn).to receive(:post).with('/v1/messages', anything).and_return(success_response)

      result = instance.create(api_key: api_key, model: model, messages: messages)

      expect(result[:status]).to eq(200)
      expect(result[:result]['id']).to eq('msg_123')
      expect(result[:result]['role']).to eq('assistant')
    end

    it 'includes optional parameters when provided' do
      allow(faraday_conn).to receive(:post).with('/v1/messages', hash_including(
                                                                   system:      'You are helpful',
                                                                   temperature: 0.7
                                                                 )).and_return(success_response)

      result = instance.create(api_key: api_key, model: model, messages: messages,
                               system: 'You are helpful', temperature: 0.7)

      expect(result[:status]).to eq(200)
    end

    it 'includes tools when provided' do
      tools = [{ name: 'get_weather', description: 'Get weather', input_schema: { type: 'object' } }]
      allow(faraday_conn).to receive(:post).with('/v1/messages', hash_including(tools: tools)).and_return(success_response)

      result = instance.create(api_key: api_key, model: model, messages: messages, tools: tools)

      expect(result[:status]).to eq(200)
    end
  end

  describe '#count_tokens' do
    let(:token_response) do
      instance_double(Faraday::Response, body: { 'input_tokens' => 42 }, status: 200, headers: {})
    end

    it 'sends a token counting request' do
      allow(faraday_conn).to receive(:post).with('/v1/messages/count_tokens', anything).and_return(token_response)

      result = instance.count_tokens(api_key: api_key, model: model, messages: messages)

      expect(result[:status]).to eq(200)
      expect(result[:result]['input_tokens']).to eq(42)
    end
  end

  describe 'error handling' do
    let(:error_response) do
      instance_double(Faraday::Response,
                      status:  429,
                      body:    { 'error' => { 'type' => 'rate_limit_error', 'message' => 'Too many requests' } },
                      headers: {})
    end

    it 'raises RateLimitError on 429 from create' do
      allow(faraday_conn).to receive(:post).with('/v1/messages', anything).and_return(error_response)
      expect { instance.create(api_key: api_key, model: model, messages: messages) }
        .to raise_error(Legion::Extensions::Claude::Helpers::Errors::RateLimitError)
    end

    it 'raises RateLimitError on 429 from count_tokens' do
      allow(faraday_conn).to receive(:post).with('/v1/messages/count_tokens', anything).and_return(error_response)
      expect { instance.count_tokens(api_key: api_key, model: model, messages: messages) }
        .to raise_error(Legion::Extensions::Claude::Helpers::Errors::RateLimitError)
    end
  end
end
