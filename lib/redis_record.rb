module RedisRecord
  require 'redis_record/backend'
  require 'redis_record/class_methods'
  require 'redis_record/instance_methods'
  require 'redis_record/exceptions'

  def self.included(base)
    base.extend(ClassMethods)
  end
end
