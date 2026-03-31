# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'
require 'legion/extensions/claude/helpers/response'

module Legion
  module Extensions
    module Claude
      module Runners
        module Models
          extend Legion::Extensions::Claude::Helpers::Client

          def list(api_key:, limit: 20, before_id: nil, after_id: nil, **)
            params = { limit: limit }
            params[:before_id] = before_id if before_id
            params[:after_id] = after_id if after_id

            response = client(api_key: api_key, **).get('/v1/models', params)
            Helpers::Response.handle_response(response)
          end

          def retrieve(api_key:, model_id:, **)
            response = client(api_key: api_key, **).get("/v1/models/#{model_id}")
            Helpers::Response.handle_response(response)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
