# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'

module Legion
  module Extensions
    module Claude
      module Runners
        module Messages
          extend Legion::Extensions::Claude::Helpers::Client

          def create(api_key:, model:, messages:, max_tokens: 1024, system: nil, temperature: nil,
                     top_p: nil, top_k: nil, stop_sequences: nil, metadata: nil, tools: nil,
                     tool_choice: nil, stream: false, **opts)
            body = {
              model:      model,
              messages:   messages,
              max_tokens: max_tokens,
              stream:     stream
            }
            body[:system] = system if system
            body[:temperature] = temperature if temperature
            body[:top_p] = top_p if top_p
            body[:top_k] = top_k if top_k
            body[:stop_sequences] = stop_sequences if stop_sequences
            body[:metadata] = metadata if metadata
            body[:tools] = tools if tools
            body[:tool_choice] = tool_choice if tool_choice

            response = client(api_key: api_key, **opts).post('/v1/messages', body)
            { result: response.body, status: response.status }
          end

          def count_tokens(api_key:, model:, messages:, system: nil, tools: nil, **opts)
            body = { model: model, messages: messages }
            body[:system] = system if system
            body[:tools] = tools if tools

            response = client(api_key: api_key, **opts).post('/v1/messages/count_tokens', body)
            { result: response.body, status: response.status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end
