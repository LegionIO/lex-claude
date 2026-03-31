# frozen_string_literal: true

# rubocop:disable Naming/VariableNumber
require 'spec_helper'
require 'legion/extensions/claude/helpers/models'

RSpec.describe Legion::Extensions::Claude::Helpers::Models do
  describe 'MODELS constant' do
    it 'includes canonical model IDs for current Claude versions' do
      expect(described_class::MODELS.keys).to include(
        :haiku_3_5, :haiku_4_5, :sonnet_3_5, :sonnet_3_7,
        :sonnet_4, :sonnet_4_5, :sonnet_4_6,
        :opus_4, :opus_4_1, :opus_4_5, :opus_4_6
      )
    end

    it 'maps sonnet_4_6 to claude-sonnet-4-6' do
      expect(described_class::MODELS[:sonnet_4_6]).to eq('claude-sonnet-4-6')
    end

    it 'maps opus_4 to claude-opus-4-20250514' do
      expect(described_class::MODELS[:opus_4]).to eq('claude-opus-4-20250514')
    end
  end

  describe '.resolve' do
    it 'passes through a full versioned model string unchanged' do
      expect(described_class.resolve('claude-sonnet-4-20250514')).to eq('claude-sonnet-4-20250514')
    end

    it 'resolves a Symbol key to the canonical model ID' do
      expect(described_class.resolve(:sonnet_4_6)).to eq('claude-sonnet-4-6')
    end

    it 'resolves a string key matching a MODELS key' do
      expect(described_class.resolve('sonnet_4_6')).to eq('claude-sonnet-4-6')
    end

    it 'returns the input unchanged if unknown' do
      expect(described_class.resolve('some-custom-model')).to eq('some-custom-model')
    end
  end

  describe '.adaptive_thinking?' do
    it 'returns true for Claude 4+ models' do
      expect(described_class.adaptive_thinking?('claude-sonnet-4-20250514')).to be true
      expect(described_class.adaptive_thinking?('claude-opus-4-6')).to be true
    end

    it 'returns false for older models' do
      expect(described_class.adaptive_thinking?('claude-3-5-haiku-20241022')).to be false
    end
  end
end
# rubocop:enable Naming/VariableNumber
