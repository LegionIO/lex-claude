# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Claude::Helpers::Client do
  let(:api_key) { 'test-key' }
  let(:faraday_conn) { instance_double(Faraday::Connection) }

  before do
    allow(Faraday).to receive(:new).and_yield(faraday_conn).and_return(faraday_conn)
    allow(faraday_conn).to receive(:request)
    allow(faraday_conn).to receive(:response)
    allow(faraday_conn).to receive(:headers).and_return({})
  end

  describe '.client' do
    it 'sets x-api-key header' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key)
      expect(headers['x-api-key']).to eq(api_key)
    end

    it 'sets anthropic-version header' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key)
      expect(headers['anthropic-version']).to eq(described_class::API_VERSION)
    end

    it 'does not set anthropic-beta when betas is nil' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key, betas: nil)
      expect(headers).not_to have_key('anthropic-beta')
    end

    it 'does not set anthropic-beta when betas is empty' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key, betas: [])
      expect(headers).not_to have_key('anthropic-beta')
    end

    it 'sets anthropic-beta header when betas is populated' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key,
                             betas:   %w[interleaved-thinking-2025-05-14 web-search-2025-03-05])
      expect(headers['anthropic-beta']).to eq('interleaved-thinking-2025-05-14,web-search-2025-03-05')
    end

    it 'accepts a single beta string' do
      headers = {}
      allow(faraday_conn).to receive(:headers).and_return(headers)
      described_class.client(api_key: api_key, betas: ['prompt-caching-scope-2026-01-05'])
      expect(headers['anthropic-beta']).to eq('prompt-caching-scope-2026-01-05')
    end
  end

  describe 'BETA_HEADERS constant' do
    it 'includes key beta identifiers' do
      expect(described_class::BETA_HEADERS).to include(
        interleaved_thinking:  'interleaved-thinking-2025-05-14',
        prompt_caching_scope:  'prompt-caching-scope-2026-01-05',
        web_search:            'web-search-2025-03-05',
        structured_outputs:    'structured-outputs-2025-12-15',
        context_management:    'context-management-2025-06-27',
        effort:                'effort-2025-11-24',
        fast_mode:             'fast-mode-2026-02-01',
        task_budgets:          'task-budgets-2026-03-13',
        token_efficient_tools: 'token-efficient-tools-2026-03-28',
        advanced_tool_use:     'advanced-tool-use-2025-11-20'
      )
    end
  end
end
