# frozen_string_literal: true

module Legion
  module Extensions
    module Claude
      module Helpers
        module Errors
          class ApiError < StandardError
            attr_reader :status, :error_type, :body

            def initialize(message = nil, status: nil, error_type: nil, body: nil)
              super(message)
              @status     = status
              @error_type = error_type
              @body       = body
            end
          end

          class AuthenticationError  < ApiError; end
          class PermissionError      < ApiError; end
          class NotFoundError        < ApiError; end
          class RateLimitError       < ApiError; end
          class OverloadedError      < ApiError; end
          class InvalidRequestError  < ApiError; end
          class ServerError          < ApiError; end
          class StreamingError       < ApiError; end

          STATUS_MAP = {
            401 => AuthenticationError,
            403 => PermissionError,
            404 => NotFoundError,
            429 => RateLimitError,
            529 => OverloadedError
          }.freeze

          TYPE_MAP = {
            'authentication_error'  => AuthenticationError,
            'permission_error'      => PermissionError,
            'not_found_error'       => NotFoundError,
            'rate_limit_error'      => RateLimitError,
            'overloaded_error'      => OverloadedError,
            'invalid_request_error' => InvalidRequestError,
            'server_error'          => ServerError,
            'streaming_error'       => StreamingError
          }.freeze

          RETRYABLE = [RateLimitError, OverloadedError].freeze

          module_function

          def from_response(status:, body:)
            error_hash  = body.is_a?(Hash) ? body[:error] : nil
            error_type  = error_hash&.fetch('type', nil)
            message     = error_hash&.fetch('message', nil) || body.to_s

            klass = TYPE_MAP[error_type] ||
                    STATUS_MAP[status] ||
                    (status >= 500 ? ServerError : InvalidRequestError)

            klass.new(message, status: status, error_type: error_type, body: body)
          end

          def retryable?(error)
            RETRYABLE.any? { |klass| error.is_a?(klass) }
          end
        end
      end
    end
  end
end
