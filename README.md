#RedisRecord

RedisRecord is a ruby gem designed to be a light-weight replacement for the popular ActiveRecord library.  RedisRecord uses the [Redis](http://redis.io) storage system instead of a traditional relational database. RedisRecord uses the `redis` gem in the background to perform all data storage communications.

###Note

RedisRecord is still very much a work in progress.  I am still in the process of adding additional specs to ensure functionality works as expected.  Additionally, some of the APIs may change as the gem moves toward a 1.0 release.  Keep this in mind as you use it in your projects, as future releases may break parts of the existing system as additional design choices are made.  Please open issues for any bugs you may find and I will fix them as quickly as I can.

##Basic Usage

To use RedisRecord in your own models, you should require the gem and have create a subclass of RedisRecord::Base:

    require 'redis_record'

    class Employee < RedisRecord::Base

      # Implementation details

    end

Once a module has inherited from RedisRecord, you may declare the properties of your model.  This will create setters and getters for the specified property name backed by the redis storage

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

##Redis Instance

If a RedisRecord is initialized without previously creating a connection to a redis server, it will attempt to connect to the default localhost instance store:

    class User < RedisRecord::Base
    end

    User.redis  # => #<Redis client v2.2.2 connected to redis://127.0.0.1:6379/0>

A custom redis connection can be assigned as follows:

    redis = Redis.new(:host => "10.0.1.1", :port => 6380)
    RedisRecord::Backend::redis_server = redis

    class User < RedisRecord::base
    end

    User.redis  # => #<Redis client v2.2.2 connected to redis://10.0.1.1:6380/0>

##Mass-assigning Attributes

It is possible to assign a number of attributes at once:

    class User < RedisRecord::Base
      property :username
      property :email
    end

    user = User.new :username => "ponyboy37", :email => "ponyboy37@gmail.com"
    user.username   # => "ponyboy37"
    user.email      # => "ponyboy37@gmail.com"

    user.attributes = {:username => "freddie3", :email => "fred.savage@gmail.com"}
    user.username   # => "freddie3"
    user.email      # => "fred.savage@gmail.com"

    user.assign_attriutes :username => "ponyboy37", :email => "ponyboy37@gmail.com"
    user.username   # => "ponyboy37"
    user.email      # => "ponyboy37@gmail.com"

RedisRecord also takes advantage of the ActiveModel library's security modifiers, which allows properties to be declared as accessible or protected:

    class User < RedisRecord::Base
      property :username
      property :email
      property :is_admin

      attr_accessible :username
      attr_accessible :email
      attr_protected :is_admin
    end

    user = User.new
    user.attributes = {:username => "freddie3", :email => "fred.savage@gmail.com", :is_admin => true}
    user.username   # => "freddie3"
    user.email      # => "fred.savage@gmail.com"
    user.is_admin   # => false 
    
##Validations

Models using RedisRecord can make use of ActiveModel's validations, which are documented [here](http://guides.rubyonrails.org/active_record_validations_callbacks.html).

    class User < RedisRecord::Base
        property :name
        validates :name, :presence => true
    end

    user = User.new

    user.valid?         # => false
    user.name = "fred"
    user.valid?         # => true

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

##License & Legal

*Copyright 2011 Wade Tandy.  All Rights Reserved.

*Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:*

*The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.*

*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.*
