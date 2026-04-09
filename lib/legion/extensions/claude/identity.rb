# frozen_string_literal: true

module Legion
  module Extensions
    module Claude
      module Identity
        module_function

        def provider_name  = :anthropic
        def provider_type  = :credential
        def facing         = nil
        def capabilities   = %i[credentials]

        def resolve(canonical_name: nil) # rubocop:disable Lint/UnusedMethodArgument
          nil
        end

        def provide_token
          api_key = resolve_api_key
          return nil unless api_key

          Legion::Identity::Lease.new(
            provider:   :anthropic,
            credential: api_key,
            expires_at: nil,
            renewable:  false,
            issued_at:  Time.now,
            metadata:   { credential_type: :api_key }
          )
        end

        def resolve_api_key
          return nil unless defined?(Legion::Settings)

          value = Legion::Settings.dig(:llm, :providers, :anthropic, :api_key)
          value = value.find { |v| v && !v.empty? } if value.is_a?(Array)
          value unless value.nil? || (value.is_a?(String) && (value.empty? || value.start_with?('env://')))
        end

        private_class_method :resolve_api_key
      end
    end
  end
end
