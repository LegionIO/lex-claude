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

          def create(api_key:, model:, messages:, max_tokens: 1024, stream: false, betas: nil, **opts)
            body = build_message_body(model: model, messages: messages, max_tokens: max_tokens, stream: stream, **opts)
            resolved_betas = resolve_feature_betas(betas, opts)

            response = client(api_key: api_key, betas: resolved_betas, **opts).post('/v1/messages', body)
            result = Helpers::Response.handle_response(response)
            result[:usage] = Helpers::Response.parse_usage(response.body) if response.body.is_a?(Hash)
            result
          end

          def create_stream(api_key:, model:, messages:, max_tokens: 1024, betas: nil, **opts, &block)
            body = build_message_body(model: model, messages: messages, max_tokens: max_tokens, stream: true, **opts)
            resolved_betas = resolve_feature_betas(betas, opts)

            raw_body = +''
            conn = Helpers::Client.streaming_client(api_key: api_key, betas: resolved_betas)
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

          def count_tokens(api_key:, model:, messages:, betas: nil, **opts)
            system       = opts[:system]
            tools        = opts[:tools]
            thinking     = opts[:thinking]
            cache_system = opts.fetch(:cache_system, false)

            body = { model: model, messages: messages }
            body[:system]   = build_system(system, cache_system) if system
            body[:tools]    = tools    if tools
            body[:thinking] = thinking if thinking

            resolved_betas = Array(betas).dup
            resolved_betas << :interleaved_thinking if thinking && !resolved_betas.include?(:interleaved_thinking)

            response = client(api_key: api_key, betas: resolved_betas).post('/v1/messages/count_tokens', body)
            result = Helpers::Response.handle_response(response)
            result[:usage] = Helpers::Response.parse_usage(response.body) if response.body.is_a?(Hash)
            result
          end

          private

          def build_message_body(model:, messages:, max_tokens:, stream:, system: nil, temperature: nil, # rubocop:disable Metrics/ParameterLists
                                 top_p: nil, top_k: nil, stop_sequences: nil, metadata: nil, tools: nil,
                                 tool_choice: nil, cache_system: false, thinking: nil, output_config: nil,
                                 fast_mode: false, context_management: nil, **)
            body = { model: model, messages: messages, max_tokens: max_tokens, stream: stream }

            body[:system]             = build_system(system, cache_system) if system
            body[:top_p]              = top_p              if top_p
            body[:top_k]              = top_k              if top_k
            body[:stop_sequences]     = stop_sequences     if stop_sequences
            body[:metadata]           = metadata           if metadata
            body[:tools]              = tools              if tools
            body[:tool_choice]        = tool_choice        if tool_choice
            body[:output_config]      = output_config      if output_config
            body[:speed]              = 'fast'             if fast_mode
            body[:context_management] = context_management if context_management

            if thinking
              body[:thinking] = thinking
            elsif temperature
              body[:temperature] = temperature
            end

            body
          end

          def resolve_feature_betas(betas, opts)
            resolved = Array(betas).dup
            resolved << :prompt_caching_scope  if opts[:cache_scope] == :global
            resolved << :interleaved_thinking  if opts[:thinking] && !resolved.include?(:interleaved_thinking)
            resolved << :structured_outputs    if opts[:output_config]&.key?(:format)
            resolved << :effort                if opts[:output_config]&.key?(:effort)
            resolved << :task_budgets          if opts[:output_config]&.key?(:task_budget)
            resolved << :fast_mode             if opts[:fast_mode]
            resolved << :context_management    if opts[:context_management]
            resolved
          end

          def build_system(system, cache_system)
            if cache_system
              [{ type: 'text', text: system, cache_control: { type: 'ephemeral' } }]
            else
              system
            end
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
