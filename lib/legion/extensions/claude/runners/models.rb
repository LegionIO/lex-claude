# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'

module Legion
  module Extensions
    module Claude
      module Runners
        module Models
          extend Legion::Extensions::Claude::Helpers::Client

          def list(api_key:, limit: 20, before_id: nil, after_id: nil, **opts)
            params = { limit: limit }
            params[:before_id] = before_id if before_id
            params[:after_id] = after_id if after_id

            response = client(api_key: api_key, **opts).get('/v1/models', params)
            { result: response.body, status: response.status }
          end

          def retrieve(api_key:, model_id:, **opts)
            response = client(api_key: api_key, **opts).get("/v1/models/#{model_id}")
            { result: response.body, status: response.status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end
