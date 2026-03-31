# frozen_string_literal: true

require 'legion/extensions/claude/version'
require 'legion/extensions/claude/helpers/client'
require 'legion/extensions/claude/helpers/errors'
require 'legion/extensions/claude/helpers/retry'
require 'legion/extensions/claude/helpers/sse'
require 'legion/extensions/claude/helpers/response'
require 'legion/extensions/claude/helpers/tools'
require 'legion/extensions/claude/helpers/models'
require 'legion/extensions/claude/runners/messages'
require 'legion/extensions/claude/runners/models'
require 'legion/extensions/claude/runners/batches'

module Legion
  module Extensions
    module Claude
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false
    end
  end
end
