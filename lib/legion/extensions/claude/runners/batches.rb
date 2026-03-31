# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'

module Legion
  module Extensions
    module Claude
      module Runners
        module Batches
          extend Legion::Extensions::Claude::Helpers::Client

          def create_batch(api_key:, requests:, **)
            body = { requests: requests }
            response = client(api_key: api_key, **).post('/v1/messages/batches', body)
            { result: response.body, status: response.status }
          end

          def list_batches(api_key:, limit: 20, before_id: nil, after_id: nil, **)
            params = { limit: limit }
            params[:before_id] = before_id if before_id
            params[:after_id] = after_id if after_id

            response = client(api_key: api_key, **).get('/v1/messages/batches', params)
            { result: response.body, status: response.status }
          end

          def retrieve_batch(api_key:, batch_id:, **)
            response = client(api_key: api_key, **).get("/v1/messages/batches/#{batch_id}")
            { result: response.body, status: response.status }
          end

          def cancel_batch(api_key:, batch_id:, **)
            response = client(api_key: api_key, **).post("/v1/messages/batches/#{batch_id}/cancel")
            { result: response.body, status: response.status }
          end

          def batch_results(api_key:, batch_id:, **)
            response = client(api_key: api_key, **).get("/v1/messages/batches/#{batch_id}/results")
            { result: response.body, status: response.status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end
