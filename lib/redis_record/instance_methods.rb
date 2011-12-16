require 'redis'
require 'active_support/core_ext/string/inflections'

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

    def destroy
      redis.del "#{klass}:id:#{@id}"
      redis.zrem "#{klass}:all", @id
      redis.del "#{klass}:id:#{@id}:hash"
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
    #     property :is_admin?
    # 
    #     attr_protected :is_admin?
    #   end
    #
    #   user = User.new
    #   user.attributes = { :username => 'Phusion'}
    #   user.username   # => "Phusion"
    #   user.is_admin?  # => false
    def attributes=(new_attributes)
      return unless new_attributes.is_a?(Hash)

      assign_attributes(new_attributes)
    end

    # Allows you to set all the attributes for a particular mass-assignment
    # security role by passing in a hash of attributes with keys matching
    # the attribute names (which again matches the column names) and the role
    # name using the :as option.
    #
    # To bypass mass-assignment security you can use the :without_protection => true
    # option.
    #
    #   class User < ActiveRecord::Base
    #     property :name
    #     property :email
    #
    #     attr_accessible :name
    #     attr_accessible :name, :is_admin, :as => :admin
    #   end
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true })
    #   user.name       # => "Josh"
    #   user.is_admin?  # => false
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true }, :as => :admin)
    #   user.name       # => "Josh"
    #   user.is_admin?  # => true
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true }, :without_protection => true)
    #   user.name       # => "Josh"
    #   user.is_admin?  # => true
    def assign_attributes(new_attributes, options = {})
      return unless new_attributes

      attributes = new_attributes.stringify_keys
      @mass_assignment_options = options

      attributes = sanitize_for_mass_assignment(attributes, mass_assignment_role)
          
      attributes.each do |key, value|
        if respond_to? "#{key}=" 
          send("#{key}=", value) 
        else
          raise(Exceptions::UnknownAttribute, "unknown attribute: #{key}")
        end 
      end

      @mass_assignment_options = nil
    end

    # Returns true if the specified +attribute+ has been set by the user or by a database load and is neither
        # nil nor empty? (the latter only applies to objects that respond to empty?, most notably Strings).
    def attribute_present?(attribute)
      value = respond_to?(attribute) ? send(attribute) : nil
      !value.nil? || (value.respond_to?(:empty?) && !value.empty?)
    end

    def id
      if !@id
        @id ||= redis.incr "#{klass}:counter"
        redis.set "#{klass}:id:#{@id}", @id 
        redis.zadd "#{klass}:all", @id, @id
      end
      @id
    end

    def ==(comparison_object)
      super ||
        comparison_object.instance_of?(self.class) &&
        id.present? &&
        comparison_object.id == id
    end
    alias :eql? :==

    def hash
      [@id].hash
    end

    def persisted?
      @id ? true : false
    end

    protected
      def id=(val)
        @id = val
      end

      def mass_assignment_options
        @mass_assignment_options ||= {}
      end

      def mass_assignment_role
        mass_assignment_options[:as] || :default
      end

      def klass
        self.class.name.underscore
      end

  end
end

