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

    it 'sets cache_control on system when cache_system: true' do
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages', hash_including(
                                system: [{ type: 'text', text: 'You are helpful',
                                           cache_control: { type: 'ephemeral' } }]
                              ))
        .and_return(success_response)

      instance.create(api_key: api_key, model: model, messages: messages,
                      system: 'You are helpful', cache_system: true)
    end

    it 'includes cache tokens in usage when present in response' do
      cached_response = instance_double(
        Faraday::Response,
        status:  200,
        body:    {
          'id'    => 'msg_cache',
          'usage' => {
            'input_tokens'                => 10,
            'output_tokens'               => 5,
            'cache_creation_input_tokens' => 200,
            'cache_read_input_tokens'     => 500
          }
        },
        headers: {}
      )
      allow(faraday_conn).to receive(:post).with('/v1/messages', anything).and_return(cached_response)

      result = instance.create(api_key: api_key, model: model, messages: messages)
      expect(result[:usage][:cache_write_tokens]).to eq(200)
      expect(result[:usage][:cache_read_tokens]).to eq(500)
    end

    context 'with extended thinking' do
      let(:thinking_config) { { type: 'enabled', budget_tokens: 5000 } }

      it 'sets thinking in the body' do
        allow(faraday_conn).to receive(:post)
          .with('/v1/messages', hash_including(thinking: thinking_config))
          .and_return(success_response)

        instance.create(api_key: api_key, model: model, messages: messages,
                        thinking: thinking_config)
      end

      it 'omits temperature when thinking is enabled' do
        allow(faraday_conn).to receive(:post) do |_path, body|
          expect(body).not_to have_key(:temperature)
          success_response
        end

        instance.create(api_key: api_key, model: model, messages: messages,
                        thinking: thinking_config, temperature: 0.9)
      end
    end

    context 'with output_config' do
      it 'sends output_config in body' do
        config = { format: { type: 'json_schema', json_schema: { type: 'object' } } }
        allow(faraday_conn).to receive(:post)
          .with('/v1/messages', hash_including(output_config: config))
          .and_return(success_response)

        instance.create(api_key: api_key, model: model, messages: messages,
                        output_config: config)
      end

      it 'sends output_config with effort' do
        config = { effort: 'high' }
        allow(faraday_conn).to receive(:post)
          .with('/v1/messages', hash_including(output_config: config))
          .and_return(success_response)

        instance.create(api_key: api_key, model: model, messages: messages,
                        output_config: config)
      end
    end

    it 'sends speed: fast when fast_mode: true' do
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages', hash_including(speed: 'fast'))
        .and_return(success_response)

      instance.create(api_key: api_key, model: model, messages: messages, fast_mode: true)
    end

    it 'sends metadata when provided' do
      meta = { user_id: 'user-abc' }
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages', hash_including(metadata: meta))
        .and_return(success_response)

      instance.create(api_key: api_key, model: model, messages: messages, metadata: meta)
    end
  end

  describe '#create_stream' do
    let(:stream_body) do
      <<~SSE
        event: message_start
        data: {"type":"message_start","message":{"id":"msg_s1","role":"assistant","content":[],"model":"claude-sonnet-4-20250514","usage":{"input_tokens":5,"output_tokens":0}}}

        event: content_block_start
        data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

        event: content_block_delta
        data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi!"}}

        event: content_block_stop
        data: {"type":"content_block_stop","index":0}

        event: message_delta
        data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":3}}

        event: message_stop
        data: {"type":"message_stop"}

      SSE
    end

    let(:stream_response) do
      instance_double(Faraday::Response, status: 200, body: stream_body, headers: {})
    end

    before do
      allow(faraday_conn).to receive(:post).with('/v1/messages', anything).and_return(stream_response)
    end

    it 'returns assembled text in result' do
      result = instance.create_stream(api_key: api_key, model: model, messages: messages)
      expect(result[:result]).to eq('Hi!')
    end

    it 'returns parsed events array' do
      result = instance.create_stream(api_key: api_key, model: model, messages: messages)
      expect(result[:events]).to be_an(Array)
      expect(result[:events].any? { |e| e[:event] == 'message_start' }).to be true
    end

    it 'returns usage hash' do
      result = instance.create_stream(api_key: api_key, model: model, messages: messages)
      expect(result[:usage][:input_tokens]).to eq(5)
      expect(result[:usage][:output_tokens]).to eq(3)
    end

    it 'yields each event when block given' do
      deltas = []
      instance.create_stream(api_key: api_key, model: model, messages: messages) do |event|
        deltas << event if event[:event] == 'content_block_delta'
      end
      expect(deltas.length).to eq(1)
      expect(deltas.first[:data]['delta']['text']).to eq('Hi!')
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

    it 'includes usage in count_tokens response' do
      resp = instance_double(Faraday::Response,
                             body:    { 'input_tokens' => 42, 'usage' => { 'input_tokens' => 42 } },
                             status:  200,
                             headers: {})
      allow(faraday_conn).to receive(:post).with('/v1/messages/count_tokens', anything).and_return(resp)

      result = instance.count_tokens(api_key: api_key, model: model, messages: messages)
      expect(result[:usage][:input_tokens]).to eq(42)
    end

    it 'includes thinking in count_tokens body when provided' do
      thinking = { type: 'enabled', budget_tokens: 2000 }
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages/count_tokens', hash_including(thinking: thinking))
        .and_return(token_response)

      result = instance.count_tokens(api_key: api_key, model: model, messages: messages,
                                     thinking: thinking)
      expect(result[:status]).to eq(200)
    end

    it 'includes tools in count_tokens body when provided' do
      tools = [{ name: 'search', description: 'Search', input_schema: { type: 'object' } }]
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages/count_tokens', hash_including(tools: tools))
        .and_return(token_response)

      instance.count_tokens(api_key: api_key, model: model, messages: messages, tools: tools)
    end

    it 'wraps system with cache_control when cache_system: true' do
      allow(faraday_conn).to receive(:post)
        .with('/v1/messages/count_tokens', hash_including(
                                             system: [{ type: 'text', text: 'Be helpful',
                                                        cache_control: { type: 'ephemeral' } }]
                                           ))
        .and_return(token_response)

      instance.count_tokens(api_key: api_key, model: model, messages: messages,
                            system: 'Be helpful', cache_system: true)
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
