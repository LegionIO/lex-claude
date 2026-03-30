# frozen_string_literal: true

require 'legion/extensions/claude/version'
require 'legion/extensions/claude/helpers/client'
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
