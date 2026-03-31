# frozen_string_literal: true

require 'multi_json'

module Legion
  module Extensions
    module Claude
      module Helpers
        module Sse
          module_function

          def parse_stream(raw, include_pings: false)
            events = []
            current_event = nil

            raw.each_line do |line|
              line = line.chomp
              if line.start_with?('event:')
                current_event = line.sub(/^event:\s*/, '').strip
              elsif line.start_with?('data:')
                next if current_event == 'ping' && !include_pings

                json_str = line.sub(/^data:\s*/, '').strip
                next if json_str.empty?

                begin
                  data = MultiJson.load(json_str)
                  events << { event: current_event, data: data }
                rescue MultiJson::ParseError => e
                  log.warn("SSE parse error: #{e.message}")
                  next
                end
                current_event = nil
              end
            end

            events
          end

          def collect_text(events)
            events
              .select { |e| e[:event] == 'content_block_delta' && e[:data].dig('delta', 'type') == 'text_delta' }
              .map { |e| e[:data].dig('delta', 'text').to_s }
              .join
          end

          def collect_usage(events)
            input_tokens  = 0
            output_tokens = 0

            events.each do |e|
              case e[:event]
              when 'message_start'
                usage = e[:data].dig('message', 'usage') || {}
                input_tokens  += usage.fetch('input_tokens', 0).to_i
                output_tokens += usage.fetch('output_tokens', 0).to_i
              when 'message_delta'
                usage = e[:data].fetch('usage', {})
                output_tokens += usage.fetch('output_tokens', 0).to_i
              end
            end

            { input_tokens: input_tokens, output_tokens: output_tokens }
          end
        end
      end
    end
  end
end
