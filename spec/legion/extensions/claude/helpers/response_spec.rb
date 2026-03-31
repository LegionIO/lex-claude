# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/claude/helpers/response'

RSpec.describe Legion::Extensions::Claude::Helpers::Response do
  let(:mod) { described_class }

  def make_response(status:, body:, headers: {})
    instance_double(Faraday::Response,
                    status:  status,
                    body:    body,
                    headers: headers)
  end

  describe '.handle_response' do
    context 'when response is 200' do
      it 'returns the result hash without raising' do
        resp = make_response(status: 200, body: { 'id' => 'msg_1' })
        result = mod.handle_response(resp)
        expect(result[:status]).to eq(200)
        expect(result[:result]).to eq({ 'id' => 'msg_1' })
      end
    end

    context 'when response is 429' do
      it 'raises RateLimitError' do
        resp = make_response(
          status: 429,
          body:   { 'error' => { 'type' => 'rate_limit_error', 'message' => 'Too many requests' } }
        )
        expect { mod.handle_response(resp) }
          .to raise_error(Legion::Extensions::Claude::Helpers::Errors::RateLimitError)
      end
    end

    context 'when response is 529' do
      it 'raises OverloadedError' do
        resp = make_response(
          status: 529,
          body:   { 'error' => { 'type' => 'overloaded_error', 'message' => 'Overloaded' } }
        )
        expect { mod.handle_response(resp) }
          .to raise_error(Legion::Extensions::Claude::Helpers::Errors::OverloadedError)
      end
    end

    context 'when response is 401' do
      it 'raises AuthenticationError' do
        resp = make_response(
          status: 401,
          body:   { 'error' => { 'type' => 'authentication_error', 'message' => 'Bad key' } }
        )
        expect { mod.handle_response(resp) }
          .to raise_error(Legion::Extensions::Claude::Helpers::Errors::AuthenticationError)
      end
    end

    context 'when response is 500' do
      it 'raises ServerError' do
        resp = make_response(
          status: 500,
          body:   { 'error' => { 'type' => 'server_error', 'message' => 'Server error' } }
        )
        expect { mod.handle_response(resp) }
          .to raise_error(Legion::Extensions::Claude::Helpers::Errors::ServerError)
      end
    end

    context 'with rate limit headers' do
      it 'includes rate_limit info in the result' do
        resp = make_response(
          status:  200,
          body:    { 'id' => 'msg_2' },
          headers: {
            'anthropic-ratelimit-unified-status'         => 'allowed',
            'anthropic-ratelimit-unified-5h-utilization' => '0.42'
          }
        )
        result = mod.handle_response(resp)
        expect(result[:rate_limit]).not_to be_nil
        expect(result[:rate_limit][:status]).to eq('allowed')
        expect(result[:rate_limit][:utilization_5h]).to eq(0.42)
      end

      it 'omits rate_limit key when no rate limit headers present' do
        resp = make_response(status: 200, body: { 'id' => 'msg_3' })
        result = mod.handle_response(resp)
        expect(result).not_to have_key(:rate_limit)
      end
    end
  end

  describe '.parse_usage' do
    it 'parses standard input/output tokens' do
      body = { 'usage' => { 'input_tokens' => 100, 'output_tokens' => 50 } }
      usage = mod.parse_usage(body)
      expect(usage[:input_tokens]).to eq(100)
      expect(usage[:output_tokens]).to eq(50)
      expect(usage[:cache_read_tokens]).to eq(0)
      expect(usage[:cache_write_tokens]).to eq(0)
    end

    it 'parses cache fields' do
      body = {
        'usage' => {
          'input_tokens'                => 10,
          'output_tokens'               => 20,
          'cache_read_input_tokens'     => 500,
          'cache_creation_input_tokens' => 300
        }
      }
      usage = mod.parse_usage(body)
      expect(usage[:cache_read_tokens]).to eq(500)
      expect(usage[:cache_write_tokens]).to eq(300)
    end

    it 'returns zeroed struct when no usage key' do
      usage = mod.parse_usage({})
      expect(usage[:input_tokens]).to eq(0)
      expect(usage[:output_tokens]).to eq(0)
    end
  end
end
