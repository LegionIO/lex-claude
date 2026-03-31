# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/claude/helpers/tools'

RSpec.describe Legion::Extensions::Claude::Helpers::Tools do
  describe '.web_search' do
    subject(:tool) { described_class.web_search }

    it 'returns a hash with type web_search_20250305' do
      expect(tool[:type]).to eq('web_search_20250305')
    end

    it 'defaults max_uses to 5' do
      expect(tool[:max_uses]).to eq(5)
    end

    it 'accepts max_uses override' do
      t = described_class.web_search(max_uses: 8)
      expect(t[:max_uses]).to eq(8)
    end

    it 'includes allowed_domains when provided' do
      t = described_class.web_search(allowed_domains: ['example.com'])
      expect(t[:allowed_domains]).to eq(['example.com'])
    end

    it 'omits allowed_domains when not provided' do
      expect(tool).not_to have_key(:allowed_domains)
    end

    it 'includes blocked_domains when provided' do
      t = described_class.web_search(blocked_domains: ['spam.com'])
      expect(t[:blocked_domains]).to eq(['spam.com'])
    end

    it 'omits blocked_domains when not provided' do
      expect(tool).not_to have_key(:blocked_domains)
    end
  end

  describe '.cache_control' do
    it 'returns an ephemeral cache_control block' do
      cc = described_class.cache_control
      expect(cc).to eq({ type: 'ephemeral' })
    end
  end

  describe '.required_betas_for' do
    it 'returns web_search beta for web_search tools' do
      tools = [described_class.web_search]
      betas = described_class.required_betas_for(tools)
      expect(betas).to include(:web_search)
    end

    it 'returns empty array for standard tools' do
      tools = [{ type: 'custom', name: 'my_tool' }]
      betas = described_class.required_betas_for(tools)
      expect(betas).to be_empty
    end
  end
end
