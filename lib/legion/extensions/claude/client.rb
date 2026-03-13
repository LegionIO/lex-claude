# frozen_string_literal: true

require 'legion/extensions/claude/helpers/client'
require 'legion/extensions/claude/runners/messages'
require 'legion/extensions/claude/runners/models'
require 'legion/extensions/claude/runners/batches'

module Legion
  module Extensions
    module Claude
      class Client
        include Legion::Extensions::Claude::Runners::Messages
        include Legion::Extensions::Claude::Runners::Models
        include Legion::Extensions::Claude::Runners::Batches

        attr_reader :config

        def initialize(api_key:, host: Helpers::Client::DEFAULT_HOST, **opts)
          @config = { api_key: api_key, host: host, **opts }
        end

        private

        def client(**override_opts)
          merged = config.merge(override_opts)
          Legion::Extensions::Claude::Helpers::Client.client(**merged)
        end
      end
    end
  end
end
