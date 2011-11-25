require 'redis'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/kernel'

module RedisRecord
  class Base
  def redis
    RedisRecord::Backend::redis_server
  end

  def id
    if !@id
      @id ||= redis.incr "#{self.class.name.underscore}:counter"
      redis.set "#{self.class.name.underscore}:id:#{@id}", @id 
      redis.rpush "#{self.class.name.underscore}:all", @id
    end
    @id
  end

  def ==(other)
    self.class == other.class and @id == other.id
  end

  protected
    def id=(val)
      @id = val
    end

  end
end

