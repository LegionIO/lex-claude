# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/claude/helpers/errors'

RSpec.describe Legion::Extensions::Claude::Helpers::Errors do
  subject(:errors) { described_class }

  describe 'class hierarchy' do
    it 'ApiError inherits from StandardError' do
      expect(described_class::ApiError.superclass).to eq(StandardError)
    end

    it 'AuthenticationError inherits from ApiError' do
      expect(described_class::AuthenticationError.superclass).to eq(described_class::ApiError)
    end

    it 'PermissionError inherits from ApiError' do
      expect(described_class::PermissionError.superclass).to eq(described_class::ApiError)
    end

    it 'NotFoundError inherits from ApiError' do
      expect(described_class::NotFoundError.superclass).to eq(described_class::ApiError)
    end

    it 'RateLimitError inherits from ApiError' do
      expect(described_class::RateLimitError.superclass).to eq(described_class::ApiError)
    end

    it 'OverloadedError inherits from ApiError' do
      expect(described_class::OverloadedError.superclass).to eq(described_class::ApiError)
    end

    it 'InvalidRequestError inherits from ApiError' do
      expect(described_class::InvalidRequestError.superclass).to eq(described_class::ApiError)
    end

    it 'ServerError inherits from ApiError' do
      expect(described_class::ServerError.superclass).to eq(described_class::ApiError)
    end

    it 'StreamingError inherits from ApiError' do
      expect(described_class::StreamingError.superclass).to eq(described_class::ApiError)
    end
  end

  describe 'ApiError attributes' do
    let(:error) do
      described_class::ApiError.new('msg', status: 400, error_type: 'invalid_request_error', body: { error: {} })
    end

    it 'exposes status' do
      expect(error.status).to eq(400)
    end

    it 'exposes error_type' do
      expect(error.error_type).to eq('invalid_request_error')
    end

    it 'exposes body' do
      expect(error.body).to eq({ error: {} })
    end

    it 'uses the message argument' do
      expect(error.message).to eq('msg')
    end
  end

  describe '.from_response' do
    context 'with status 401' do
      let(:body) { { error: { 'type' => 'authentication_error', 'message' => 'Invalid API key' } } }

      it 'returns AuthenticationError' do
        error = errors.from_response(status: 401, body: body)
        expect(error).to be_a(described_class::AuthenticationError)
      end

      it 'sets status' do
        expect(errors.from_response(status: 401, body: body).status).to eq(401)
      end

      it 'sets error_type' do
        expect(errors.from_response(status: 401, body: body).error_type).to eq('authentication_error')
      end

      it 'sets message from body' do
        expect(errors.from_response(status: 401, body: body).message).to eq('Invalid API key')
      end
    end

    context 'with status 403' do
      let(:body) { { error: { 'type' => 'permission_error', 'message' => 'Forbidden' } } }

      it 'returns PermissionError' do
        expect(errors.from_response(status: 403, body: body)).to be_a(described_class::PermissionError)
      end
    end

    context 'with status 404' do
      let(:body) { { error: { 'type' => 'not_found_error', 'message' => 'Not found' } } }

      it 'returns NotFoundError' do
        expect(errors.from_response(status: 404, body: body)).to be_a(described_class::NotFoundError)
      end
    end

    context 'with status 429' do
      let(:body) { { error: { 'type' => 'rate_limit_error', 'message' => 'Rate limit exceeded' } } }

      it 'returns RateLimitError' do
        expect(errors.from_response(status: 429, body: body)).to be_a(described_class::RateLimitError)
      end
    end

    context 'with status 529' do
      let(:body) { { error: { 'type' => 'overloaded_error', 'message' => 'API overloaded' } } }

      it 'returns OverloadedError' do
        expect(errors.from_response(status: 529, body: body)).to be_a(described_class::OverloadedError)
      end
    end

    context 'with status 400' do
      let(:body) { { error: { 'type' => 'invalid_request_error', 'message' => 'Bad request' } } }

      it 'returns InvalidRequestError' do
        expect(errors.from_response(status: 400, body: body)).to be_a(described_class::InvalidRequestError)
      end
    end

    context 'with status 500' do
      let(:body) { { error: { 'type' => 'server_error', 'message' => 'Internal server error' } } }

      it 'returns ServerError' do
        expect(errors.from_response(status: 500, body: body)).to be_a(described_class::ServerError)
      end
    end

    context 'with status 503 and no error key in body' do
      let(:body) { { 'message' => 'service unavailable' } }

      it 'returns ServerError for 5xx without known error type' do
        expect(errors.from_response(status: 503, body: body)).to be_a(described_class::ServerError)
      end
    end

    context 'with status 422 and missing error key' do
      let(:body) { { 'message' => 'Unprocessable entity' } }

      it 'returns InvalidRequestError for 4xx without known error type' do
        expect(errors.from_response(status: 422, body: body)).to be_a(described_class::InvalidRequestError)
      end
    end
  end

  describe '.retryable?' do
    it 'returns true for RateLimitError' do
      error = described_class::RateLimitError.new('rate limited')
      expect(errors.retryable?(error)).to be true
    end

    it 'returns true for OverloadedError' do
      error = described_class::OverloadedError.new('overloaded')
      expect(errors.retryable?(error)).to be true
    end

    it 'returns false for AuthenticationError' do
      error = described_class::AuthenticationError.new('unauthorized')
      expect(errors.retryable?(error)).to be false
    end

    it 'returns false for InvalidRequestError' do
      error = described_class::InvalidRequestError.new('bad request')
      expect(errors.retryable?(error)).to be false
    end

    it 'returns false for ServerError' do
      error = described_class::ServerError.new('server error')
      expect(errors.retryable?(error)).to be false
    end
  end
end
