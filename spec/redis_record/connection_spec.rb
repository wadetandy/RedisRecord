require 'spec_helper'

describe RedisRecord::Connection do
  before (:each) do
    class User 
      include RedisRecord::Connection
    end
  end

  describe "Class Methods" do

    it "should have a redis connection accessor" do
      User.respond_to?("redis").should eq true
    end

    it "should use the standard Redis connection by default" do
      RedisRecord::Base.redis.should eq @redis_mock
    end

    it "should be able to specify a custom Redis connection for the class" do
      @redis_mock_custom = MockRedis.new
      User.redis = @redis_mock_custom
      User.redis.should eq @redis_mock_custom
      
      # Reset for the next test
      User.redis = nil
    end

    it "should use the Redis connection of its parent class by default" do
      class Admin < User
      end

      @redis_mock_custom = MockRedis.new
      User.redis = @redis_mock_custom
      Admin.redis.should eq @redis_mock_custom

      User.redis = nil
      Admin.redis.should eq @redis_mock
    end

  end

  describe "Instance Methods" do
    before (:each) do
      @user = User.new
    end

    it "should use the standard Redis connection by default" do
      @user.redis.should eq RedisRecord::Backend::redis_server 
    end

    it "should use the Redis connection of its class if one is declared" do
      @redis_mock_custom = MockRedis.new
      User.redis = @redis_mock_custom
      @user.redis.should eq @redis_mock_custom

      User.redis = nil
    end

    it "should be able to specify a custom Redis connection for a given instance" do
      @redis_mock_custom = MockRedis.new
      @user.redis = @redis_mock_custom
      User.redis.should eq @redis_mock
      @user.redis.should eq @redis_mock_custom
    end

  end

  after (:each) do
    Object.send(:remove_const, :User)
  end
end
