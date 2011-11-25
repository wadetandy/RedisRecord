require 'spec_helper'

class ActiveRedisModel < RedisRecord::Base
end

describe ActiveRedisModel do
  it_should_behave_like "ActiveModel"
end
