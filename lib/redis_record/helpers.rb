require 'active_support/core_ext/string/inflections'
require 'active_support/concern'

module RedisRecord
  module Helpers
    extend ActiveSupport::Concern

    module ClassMethods
      protected
        def klass
          self.name.underscore
        end
    end

    protected
      def klass
        self.class.name.underscore
      end
  end
end
