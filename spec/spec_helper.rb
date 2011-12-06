require 'rubygems'
require 'bundler/setup'

require 'redis_record' 
require 'mock_redis'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.before(:each) do
    RedisRecord::Backend::redis_server = MockRedis.new
    @redis_mock = RedisRecord::Backend::redis_server
  end
end
