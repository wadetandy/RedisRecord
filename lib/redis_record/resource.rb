require 'redis'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/kernel'

module RedisRecord
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@properties ||= Set.new

    # Allow declaration of class properties that are backed by
    # a Redis store
    # 
    # To declare a property, do the following in the class definition:
    #   property :property_name
    def property (*args)
      options = args.extract_options!
      unique = false
      searchable = false

      # Each property value allows the declaration of a number of options.  This switch statement iterates through the hash of all options provided to the property and processes them accordingly.
      options.each do |key, value|
        case key.to_sym
        when :searchable
          if value == true
            searchable = true
            unique = true
          end
        else
          raise "Invalid property option"
        end
      end

      args.each do |sym|
        klass = self.name.downcase
        @@properties << sym

        define_method(sym) do
          redis.get "#{klass}:id:#{id}:#{sym}"
        end

        define_method("#{sym}=") do |value|
          if respond_to? "check_#{sym}_uniqueness"
            send("check_#{sym}_uniqueness", value)
          end

          redis.set "#{klass}:id:#{id}:#{sym}", value
        end

        # After creating general methods, deal with other optional methods
        if unique
          define_method("check_#{sym}_uniqueness") do |value|
            found_id = redis.get "#{klass}:#{sym}:#{value}"
            if found_id
              if found_id != id
                raise "A #{self.class.name} with that #{sym} already exists!"
              end
            else
              if send(sym)
                redis.del "#{klass}:#{sym}:#{value}"
              end
              redis.set "#{klass}:#{sym}:#{value}", id
            end
          end
        end

        if searchable
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

    def find(id)
      found_id = redis.get "#{self.class.name.underscore}:id:#{id}"

      if found_id
        object = self.new# :id => found_id        
        object.id = found_id
        object
      end
    end

    def all
      #user_count = redis.llen "#{self.class.name.underscore}:all"
      id_list = redis.lrange "#{self.class.name.underscore}:all", 0, -1

      obj_list = []
      id_list.each do |obj_id|
        obj = self.new
        obj.id = obj_id
        obj_list << obj
      end

      obj_list
    end
        
    def redis
      @@redis ||= Redis.new
    end

    def class_underscore
      self.to_s.underscore 
    end
  end

  def initialize(hash = {})
    hash.each do |key, value|
      if properties.include?(key)
        send("#{attribute}=", hash[attribute.to_sym])
      end
#
#      if key == :id
#        @id = value
#      end
    end
  end

  def properties
    @@properties ||= Set.new
  end

  def is_new
    @@is_new ||= true
  end
    
  def redis
    @@redis ||= Redis.new
  end

  def id
    if !@id
      redis.multi do
        @id ||= redis.incr "#{self.class.name.underscore}:counter"
        redis.set "#{self.class.name.underscore}:id:#{@id}", @id 
        redis.rpush "#{self.class.name.underscore}:all", @id
      end
    end
    @id
  end
  
  def id=(val)
    @id = val
  end

  def ==(other)
    self.class == other.class and @id == other.id
  end
end

