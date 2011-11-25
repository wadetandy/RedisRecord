#RedisRecord

RedisRecord is a ruby gem created to allow developers to easily store model data to [Redis](http://redis.io) storage system.


#Basic Usage

To use RedisRecord in your own models, you should require the gem and include the RedisRecord module in your class definition:

    require 'redis_record'

    class Employee
      include RedisRecord

      # Implementation details

    end

Once you have included the RedisRecord module, you may declare the properties of your model.  This will create setters and getters for the specified property name backed by the redis storage

    require 'redis_record'

    class Employee
      include RedisRecord

      property :name
    end

    emp = Employee.new

    emp.name            # => nil
    emp.name = "Fred"   # => Stores to redis server
    emp.name            # => "Fred"

Additionally, all RedisRecord models have an `id` property that is automatically created.  This property differs from the others, however, in that it is read only:

    class Employee
      include RedisRecord
    end

    emp = Employee.new
    
    emp.id      # => 3
    emp.id      # => NoMethodError: protected method `id=' called for #<Employee:0x9023>

##Search

Any model that uses RedisRecord gets the ability to search for objects by the `id` property:

    class Employee
      include RedisRecord

      property :name
    end

    emp = Employee.new

    emp.name = "Fred"   
    emp.id  # => 3

    emp2 = Employee.find(3)

    emp2.name # => "Fred"

You may also retrieve all instances of a given class:

    employees = Employee.all

    employees.each do |emp|
        # Do stuff
    end

