# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/claude/helpers/retry'

RSpec.describe Legion::Extensions::Claude::Helpers::Retry do
  let(:mod) { described_class }

  describe '.with_retry' do
    it 'returns the block result on first success' do
      result = mod.with_retry { 42 }
      expect(result).to eq(42)
    end

    it 'retries on a retryable error and eventually succeeds' do
      attempts = 0
      result = mod.with_retry(max_attempts: 3, base_delay: 0) do
        attempts += 1
        raise Legion::Extensions::Claude::Helpers::Errors::RateLimitError.new('rate', status: 429) if attempts < 3

        'success'
      end
      expect(result).to eq('success')
      expect(attempts).to eq(3)
    end

    it 'raises immediately on non-retryable errors' do
      attempts = 0
      expect do
        mod.with_retry(max_attempts: 3, base_delay: 0) do
          attempts += 1
          raise Legion::Extensions::Claude::Helpers::Errors::AuthenticationError.new('bad key', status: 401)
        end
      end.to raise_error(Legion::Extensions::Claude::Helpers::Errors::AuthenticationError)
      expect(attempts).to eq(1)
    end

    it 'raises after exhausting max_attempts' do
      expect do
        mod.with_retry(max_attempts: 2, base_delay: 0) do
          raise Legion::Extensions::Claude::Helpers::Errors::OverloadedError.new('busy', status: 529)
        end
      end.to raise_error(Legion::Extensions::Claude::Helpers::Errors::OverloadedError)
    end

    it 're-raises non-ApiError exceptions immediately' do
      expect do
        mod.with_retry(max_attempts: 3, base_delay: 0) do
          raise ArgumentError, 'bad arg'
        end
      end.to raise_error(ArgumentError)
    end
  end

  describe '.backoff_seconds' do
    it 'returns base_delay * 2^attempt' do
      expect(mod.backoff_seconds(attempt: 0, base_delay: 1.0)).to eq(1.0)
      expect(mod.backoff_seconds(attempt: 1, base_delay: 1.0)).to eq(2.0)
      expect(mod.backoff_seconds(attempt: 2, base_delay: 1.0)).to eq(4.0)
    end

    it 'caps at max_delay' do
      expect(mod.backoff_seconds(attempt: 20, base_delay: 1.0, max_delay: 30.0)).to eq(30.0)
    end
  end
end
