# frozen_string_literal: true

module Legion
  module Extensions
    module Claude
      module Helpers
        module Models
          # rubocop:disable Naming/VariableNumber
          MODELS = {
            haiku_3_5:  'claude-3-5-haiku-20241022',
            haiku_4_5:  'claude-haiku-4-5-20251001',
            sonnet_3_5: 'claude-3-5-sonnet-20241022',
            sonnet_3_7: 'claude-3-7-sonnet-20250219',
            sonnet_4:   'claude-sonnet-4-20250514',
            sonnet_4_5: 'claude-sonnet-4-5-20250929',
            sonnet_4_6: 'claude-sonnet-4-6',
            opus_4:     'claude-opus-4-20250514',
            opus_4_1:   'claude-opus-4-1-20250805',
            opus_4_5:   'claude-opus-4-5-20251101',
            opus_4_6:   'claude-opus-4-6'
          }.freeze
          # rubocop:enable Naming/VariableNumber

          ADAPTIVE_THINKING_MODELS = %w[
            claude-sonnet-4-20250514
            claude-sonnet-4-5-20250929
            claude-sonnet-4-6
            claude-opus-4-20250514
            claude-opus-4-1-20250805
            claude-opus-4-5-20251101
            claude-opus-4-6
          ].freeze

          module_function

          def resolve(model)
            key = model.is_a?(Symbol) ? model : model.to_s.to_sym
            MODELS.fetch(key, model.to_s)
          end

          def adaptive_thinking?(model_id)
            ADAPTIVE_THINKING_MODELS.include?(model_id.to_s)
          end
        end
      end
    end
  end
end
