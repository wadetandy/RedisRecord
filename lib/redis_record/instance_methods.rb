require 'redis'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/kernel'

module RedisRecord
  class Base
    def redis
      RedisRecord::Backend::redis_server
    end

    def initialize(attributes = nil)
      @attributes = Hash.new
      self.class.properties.each do |key|
        @attributes[key] = nil
      end

      assign_attributes(attributes) if attributes
    end

    # Returns true if the given attribute is in the attributes hash
    def has_attribute?(attr_name)
      @attributes.has_key?(attr_name.to_sym)
    end

    # Returns an array of names for the attributes available on this object.
    def attribute_names
      @attributes.keys
    end

    # Allows you to set all the attributes at once by passing in a hash with keys
    # matching the attribute names (which again matches the property names).
    #
    #   class User < RedisRecord::Base
    #     property :username
    #   end
    #
    #   user = User.new
    #   user.attributes = { :username => 'Phusion'}
    #   user.username   # => "Phusion"
    def attributes=(new_attributes)
      return unless new_attributes.is_a?(Hash)

      assign_attributes(new_attributes)
    end

    def assign_attributes(new_attributes)
      return unless new_attributes

      new_attributes.each do |key, value|
        if self.methods.include? "#{key}="
          self.send("#{key}=", value)
        end
      end
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

    def persisted?
      @id ? true : false
    end

    protected
      def id=(val)
        @id = val
      end

  end
end

