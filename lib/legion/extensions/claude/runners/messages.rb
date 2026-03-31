# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'
require 'legion/extensions/claude/helpers/response'
require 'legion/extensions/claude/helpers/sse'

module Legion
  module Extensions
    module Claude
      module Runners
        module Messages
          extend Legion::Extensions::Claude::Helpers::Client

          def create(api_key:, model:, messages:, max_tokens: 1024, system: nil, temperature: nil, # rubocop:disable Metrics/ParameterLists
                     top_p: nil, top_k: nil, stop_sequences: nil, metadata: nil, tools: nil,
                     tool_choice: nil, stream: false, betas: nil, **)
            body = {
              model:      model,
              messages:   messages,
              max_tokens: max_tokens,
              stream:     stream
            }
            body[:system]         = system         if system
            body[:temperature]    = temperature    if temperature
            body[:top_p]          = top_p          if top_p
            body[:top_k]          = top_k          if top_k
            body[:stop_sequences] = stop_sequences if stop_sequences
            body[:metadata]       = metadata       if metadata
            body[:tools]          = tools          if tools
            body[:tool_choice]    = tool_choice    if tool_choice

            response = client(api_key: api_key, betas: betas, **).post('/v1/messages', body)
            Helpers::Response.handle_response(response)
          end

          def create_stream(api_key:, model:, messages:, max_tokens: 1024, system: nil, # rubocop:disable Metrics/ParameterLists
                            temperature: nil, top_p: nil, top_k: nil, stop_sequences: nil,
                            metadata: nil, tools: nil, tool_choice: nil, betas: nil, **, &block)
            body = {
              model:      model,
              messages:   messages,
              max_tokens: max_tokens,
              stream:     true
            }
            body[:system]         = system         if system
            body[:temperature]    = temperature    if temperature
            body[:top_p]          = top_p          if top_p
            body[:top_k]          = top_k          if top_k
            body[:stop_sequences] = stop_sequences if stop_sequences
            body[:metadata]       = metadata       if metadata
            body[:tools]          = tools          if tools
            body[:tool_choice]    = tool_choice    if tool_choice

            raw_body = +''
            conn = Helpers::Client.streaming_client(api_key: api_key, betas: betas)
            response = conn.post('/v1/messages', MultiJson.dump(body)) do |req|
              req.options.on_data = proc { |chunk, _bytes| raw_body << chunk }
            end

            raise Helpers::Errors.from_response(status: response.status, body: {}) unless response.status == 200

            raw_body = response.body if raw_body.empty? && response.body.is_a?(String)

            events = Helpers::Sse.parse_stream(raw_body)
            events.each(&block) if block

            {
              result: Helpers::Sse.collect_text(events),
              events: events,
              usage:  Helpers::Sse.collect_usage(events),
              status: 200
            }
          end

          def count_tokens(api_key:, model:, messages:, system: nil, tools: nil, betas: nil, **)
            body = { model: model, messages: messages }
            body[:system] = system if system
            body[:tools]  = tools  if tools

            response = client(api_key: api_key, betas: betas, **).post('/v1/messages/count_tokens', body)
            Helpers::Response.handle_response(response)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
