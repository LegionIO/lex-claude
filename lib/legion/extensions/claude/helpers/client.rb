# frozen_string_literal: true

require 'faraday'
require 'multi_json'

module Legion
  module Extensions
    module Claude
      module Helpers
        module Client
          DEFAULT_HOST = 'https://api.anthropic.com'
          API_VERSION  = '2023-06-01'

          BETA_HEADERS = {
            interleaved_thinking:  'interleaved-thinking-2025-05-14',
            context_1m:            'context-1m-2025-08-07',
            context_management:    'context-management-2025-06-27',
            structured_outputs:    'structured-outputs-2025-12-15',
            web_search:            'web-search-2025-03-05',
            advanced_tool_use:     'advanced-tool-use-2025-11-20',
            effort:                'effort-2025-11-24',
            task_budgets:          'task-budgets-2026-03-13',
            prompt_caching_scope:  'prompt-caching-scope-2026-01-05',
            fast_mode:             'fast-mode-2026-02-01',
            redact_thinking:       'redact-thinking-2026-02-12',
            token_efficient_tools: 'token-efficient-tools-2026-03-28',
            summarize_connector:   'summarize-connector-text-2026-03-13',
            afk_mode:              'afk-mode-2026-01-31',
            advisor:               'advisor-tool-2026-03-01',
            files_api:             'files-api-2025-04-14',
            claude_code:           'claude-code-20250219',
            tool_search:           'tool-search-tool-2025-10-19'
          }.freeze

          module_function

          def client(api_key:, host: DEFAULT_HOST, betas: nil, **_opts)
            beta_list = resolve_betas(betas)

            Faraday.new(url: host) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.headers['x-api-key'] = api_key
              conn.headers['anthropic-version']  = API_VERSION
              conn.headers['Content-Type']       = 'application/json'
              conn.headers['anthropic-beta']     = beta_list.join(',') if beta_list.any?
            end
          end

          def resolve_betas(betas)
            return [] if betas.nil? || betas.empty?

            betas.filter_map do |b|
              b.is_a?(Symbol) ? BETA_HEADERS[b] : b.to_s
            end.uniq
          end
        end
      end
    end
  end
end
