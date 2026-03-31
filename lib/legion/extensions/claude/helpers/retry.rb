# frozen_string_literal: true

require 'legion/extensions/claude/helpers/errors'

module Legion
  module Extensions
    module Claude
      module Helpers
        module Retry
          DEFAULT_MAX_ATTEMPTS = 3
          DEFAULT_BASE_DELAY   = 1.0
          DEFAULT_MAX_DELAY    = 60.0

          module_function

          def with_retry(max_attempts: DEFAULT_MAX_ATTEMPTS, base_delay: DEFAULT_BASE_DELAY,
                         max_delay: DEFAULT_MAX_DELAY)
            attempt = 0
            begin
              yield
            rescue Errors::ApiError => e
              raise unless Errors.retryable?(e)

              attempt += 1
              raise if attempt >= max_attempts

              delay = backoff_seconds(attempt: attempt - 1, base_delay: base_delay, max_delay: max_delay)
              sleep(delay) if delay.positive?
              retry
            end
          end

          def backoff_seconds(attempt:, base_delay: DEFAULT_BASE_DELAY, max_delay: DEFAULT_MAX_DELAY)
            raw = base_delay * (2**attempt)
            [raw, max_delay].min.to_f
          end
        end
      end
    end
  end
end
