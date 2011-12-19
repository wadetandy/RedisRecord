module RedisRecord
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

  end

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
          
      # Access the Redis connection directly
      def redis
        @@redis ||= Hash.new

        if superclass != Object
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

      # We need to keep track of each class' properties.  Since the @@properties class variable 
      # will be shared by all classes implementing RedisRecord, we will assign each model 
      # a member of a hash named after the class.
      def properties
        @@properties ||= Hash.new

        @@properties[self.name] ||= Set.new << :id
      end

      protected
        def klass
          self.name.underscore
        end
    end
  end
end
