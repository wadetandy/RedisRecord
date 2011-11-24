require 'redis'

# The backend module allows you to specify the redis connection you would like to use. The RedisRecord methods use this connections to do their work
module RedisRecord
  module Backend
    def self.redis_server
      @@redis_server ||= Redis.new
    end

    def self.redis_server=(server)
      @@redis_server = server
    end
  end
end
