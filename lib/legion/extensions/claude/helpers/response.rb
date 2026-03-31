# frozen_string_literal: true

require 'legion/extensions/claude/helpers/errors'

module Legion
  module Extensions
    module Claude
      module Helpers
        module Response
          RATE_LIMIT_HEADERS = {
            'anthropic-ratelimit-unified-status'         => :status,
            'anthropic-ratelimit-unified-reset'          => :reset,
            'anthropic-ratelimit-unified-fallback'       => :fallback,
            'anthropic-ratelimit-unified-5h-utilization' => :utilization_5h,
            'anthropic-ratelimit-unified-5h-reset'       => :reset_5h,
            'anthropic-ratelimit-unified-7d-utilization' => :utilization_7d,
            'anthropic-ratelimit-unified-7d-reset'       => :reset_7d,
            'anthropic-ratelimit-unified-overage-status' => :overage_status,
            'anthropic-ratelimit-unified-overage-reset'  => :overage_reset
          }.freeze

          FLOAT_KEYS = %i[utilization_5h utilization_7d].freeze

          module_function

          def handle_response(response)
            raise Errors.from_response(status: response.status, body: response.body) unless response.status >= 200 && response.status < 300

            result = { result: response.body, status: response.status }
            rate_info = parse_rate_limit_headers(response.headers)
            result[:rate_limit] = rate_info unless rate_info.empty?
            result
          end

          def parse_rate_limit_headers(headers)
            return {} if headers.nil? || headers.empty?

            parsed = {}
            RATE_LIMIT_HEADERS.each do |header_name, key|
              value = headers[header_name]
              next if value.nil?

              parsed[key] = FLOAT_KEYS.include?(key) ? value.to_f : value
            end
            parsed
          end

          def parse_usage(body)
            usage = body.is_a?(Hash) ? (body[:usage] || body['usage'] || {}) : {} # rubocop:disable Legion/Framework/ApiStringKeys
            {
              input_tokens:       (usage[:input_tokens] || usage['input_tokens'] || 0).to_i,
              output_tokens:      (usage[:output_tokens] || usage['output_tokens'] || 0).to_i,
              cache_read_tokens:  (usage[:cache_read_input_tokens] || usage['cache_read_input_tokens'] || 0).to_i,
              cache_write_tokens: (usage[:cache_creation_input_tokens] || usage['cache_creation_input_tokens'] || 0).to_i
            }
          end
        end
      end
    end
  end
end
