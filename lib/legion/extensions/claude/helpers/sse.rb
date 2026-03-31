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
            totals = Hash.new(0)

            events.each do |e|
              case e[:event]
              when 'message_start'
                merge_usage(totals, e[:data].dig('message', 'usage'))
              when 'message_delta'
                merge_usage(totals, e[:data]['usage'])
              end
            end

            {
              input_tokens:              totals['input_tokens'],
              output_tokens:             totals['output_tokens'],
              cache_read_tokens:         totals['cache_read_input_tokens'],
              cache_write_tokens:        totals['cache_creation_input_tokens'],
              cache_ephemeral_1h_tokens: totals['ephemeral_1h_input_tokens'],
              cache_ephemeral_5m_tokens: totals['ephemeral_5m_input_tokens'],
              cache_deleted_tokens:      totals['cache_deleted_input_tokens']
            }
          end

          def merge_usage(totals, usage)
            return unless usage.is_a?(Hash)

            usage.each do |key, val|
              if val.is_a?(Hash)
                val.each { |k, v| totals[k.to_s] += v.to_i }
              else
                totals[key.to_s] += val.to_i
              end
            end
          end
        end
      end
    end
  end
end
