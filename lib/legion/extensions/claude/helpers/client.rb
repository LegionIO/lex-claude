# frozen_string_literal: true

require 'faraday'
require 'multi_json'

module Legion
  module Extensions
    module Claude
      module Helpers
        module Client
          DEFAULT_HOST = 'https://api.anthropic.com'
          API_VERSION = '2023-06-01'

          def client(api_key:, host: DEFAULT_HOST, **_opts)
            Faraday.new(url: host) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.headers['x-api-key'] = api_key
              conn.headers['anthropic-version'] = API_VERSION
              conn.headers['Content-Type'] = 'application/json'
            end
          end
        end
      end
    end
  end
end
