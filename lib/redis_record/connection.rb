require 'redis'
require 'redis_record/helpers'
require 'active_support/concern'

module RedisRecord
  module Connection
    extend ActiveSupport::Concern
    include Helpers

    module ClassMethods
      # Access the Redis connection used by the class.
      # Default connection is the connection used by the superclass
      # (and RedisRecord::Backend::redis_server) in the case of the 
      # a non-inherited class
      def redis
        @@redis ||= Hash.new

        if superclass.respond_to? "redis"
          @@redis[klass] || superclass.redis
        else
          @@redis[klass] || RedisRecord::Backend::redis_server
        end
      end

      # Sets a custom Redis connection for this and all subclasses
      def redis=(redis_object)
        @@redis ||= Hash.new
        @@redis[klass] = redis_object
      end
    end
    
    # Returns the Redis connection used by the instance (defaults to whatever
    # connection is used by the class.
    def redis
      @redis ||= self.class.redis
    end

    # Sets the instance to use a specific Redis connection which may be different than that of the class default
    def redis=(redis_connection)
      @redis = redis_connection
    end
  end
end
