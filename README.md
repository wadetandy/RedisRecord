#RedisRecord

RedisRecord is a ruby gem created to allow developers to easily store model data to [Redis](http://redis.io) storage system.


#Basic Usage

To use RedisRecord in your own models, you should require the gem and have create a subclass of RedisRecord::Base:

    require 'redis_record'

    class Employee < RedisRecord::Base

      # Implementation details

    end

Once you have included the RedisRecord module, you may declare the properties of your model.  This will create setters and getters for the specified property name backed by the redis storage

    require 'redis_record'

    class Employee < RedisRecord::Base
      property :name
    end

    emp = Employee.new

    emp.name            # => nil
    emp.name = "Fred"   # => Stores to redis server
    emp.name            # => "Fred"

Additionally, all RedisRecord models have an `id` property that is automatically created.  This property differs from the others, however, in that it is read only:

    class Employee < RedisRecord::Base
    end

    emp = Employee.new
    
    emp.id      # => 3
    emp.id      # => NoMethodError: protected method `id=' called for #<Employee:0x9023>

##Search

Any model that uses RedisRecord gets the ability to search for objects by the `id` property:

    class Employee < RedisRecord::Base
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

License & Legal
==============

*Copyright 2011 Wade Tandy.  All Rights Reserved.

*Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:*

*The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.*

*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.*
