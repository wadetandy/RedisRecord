#RedisRecord

RedisRecord is a ruby gem created to allow developers to easily store model data to Redis storage system.


#Usage

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
      property :description

    end



