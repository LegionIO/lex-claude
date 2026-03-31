# frozen_string_literal: true

module Legion
  module Extensions
    module Claude
      module Helpers
        module Tools
          module_function

          def web_search(max_uses: 5, allowed_domains: nil, blocked_domains: nil)
            tool = { type: 'web_search_20250305', max_uses: max_uses }
            tool[:allowed_domains] = allowed_domains if allowed_domains
            tool[:blocked_domains] = blocked_domains if blocked_domains
            tool
          end

          def cache_control
            { type: 'ephemeral' }
          end

          def required_betas_for(tools)
            return [] if tools.nil? || tools.empty?

            betas = []
            betas << :web_search if tools.any? { |t| t.is_a?(Hash) && t[:type].to_s.start_with?('web_search') }
            betas
          end
        end
      end
    end
  end
end
