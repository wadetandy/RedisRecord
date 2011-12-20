require 'redis'
require 'active_support/core_ext/string/inflections'
require 'active_model'

module RedisRecord
  class Base
    class << self
      # Allow declaration of class properties that are backed by
      # a Redis store
      # 
      # To declare a property, do the following in the class definition:
      #   property :property_name
      def property (*args)
        options = args.extract_options!
        searchable = false

        # Each property value allows the declaration of a number of options.  This switch statement iterates through the hash of all options provided to the property and processes them accordingly.
        options.each do |key, value|
          case key.to_sym
          when :searchable
            if value == true
              searchable = true
            end
          else
            raise RedisRecord::Exceptions::InvalidPropertyOption
          end
        end

        args.each do |sym|
          # Make sure we consistently use symbols, otherwise we could end up with duplicate properties
          sym = sym.to_sym 

          if properties.include? sym
            raise RedisRecord::Exceptions::PropertyExists
          end

          properties << sym

          define_attribute_method sym

          define_method(sym) do
            @attributes[sym] ||= redis.hget "#{klass}:id:#{id}:hash", sym
          end

          define_method("#{sym}=") do |value|
            if respond_to? "check_#{sym}_uniqueness"
              send("check_#{sym}_uniqueness", value)
            end

            send("#{sym}_will_change!") unless value == send(sym)
            @attributes[sym] = value 
            redis.hset "#{klass}:id:#{id}:hash", sym, value
          end

          # After creating methods for every case, deal with other optional methods

          # Create methods to search for the model by this property
          # For now this means that this value must be unique
          # TODO: Decouple searchability and uniqueness
          if searchable
            define_method("check_#{sym}_uniqueness") do |value|
              found_id = redis.get "#{klass}:#{sym}:#{value}"
              if found_id
                if found_id != id
                  raise RedisRecord::Exceptions::NotUnique
                end
              else
                if send(sym)
                  redis.del "#{klass}:#{sym}:#{value}"
                end
                redis.set "#{klass}:#{sym}:#{value}", id
              end
            end

            singleton_class.class_eval do
              define_method("find_by_#{sym.to_s.underscore}") do |value|
                found_id = redis.get "#{klass}:#{sym}:#{value}"
                if found_id
                  object = self.new :id => found_id
                end
              end
            end
          end

        end
      end

      # Every RedisResource is searchable by the id property
      def find(id)
        found_id = redis.get "#{klass}:id:#{id}"

        if found_id
          object = self.new
          object.send(:id=, found_id.to_i)
          object
        end
      end

      # Retrieve every instance of the current object
      def all
        id_list = redis.zrange "#{klass}:all", 0, -1

        obj_list = []
        id_list.each do |obj_id|
          obj = self.new
          obj.send(:id=, obj_id.to_i)
          obj_list << obj
        end

        obj_list
      end

      # We need to keep track of each class' properties.  Since the @@properties class variable 
      # will be shared by all classes implementing RedisRecord, we will assign each model 
      # a member of a hash named after the class.
      def properties
        @@properties ||= Hash.new

        @@properties[self.name] ||= Set.new << :id
      end
    end

    public
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

    include Connection
    include Helpers

    # ActiveModel functionality
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Dirty
  end
end

