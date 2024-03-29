require 'spec_helper'

describe RedisRecord::Base do
  before(:all) do
  end

  before(:each) do
    class User < RedisRecord::Base
    end

    @user = User.new
  end

  it "should allow a property to be declared" do
    User.property :name
    User.properties.include?(:name).should eq true
  end

  it "should use a custom redis instance if one is declared" do
    User.redis.should eq @redis_mock
  end

  it "should create a getter when a property is declared" do
    @user.respond_to?(:name).should eq false
    User.property :name
    @user.respond_to?(:name).should eq true
  end

  it "should create a setter when a property is declared" do
    @user.respond_to?(:name=).should eq false
    User.property :name
    @user.respond_to?(:name=).should eq true
  end

  it "should be searchable by id" do
    @redis_mock.set "user:id:4", 4
    
    result = User.find(4)
    result.id.should eq 4
  end

  it "should be nil if the requested id isn't found" do
    result = User.find(4)
    result.should eq nil
  end

  it "should be able to retrieve all objects" do
    @user2 = User.new
    @user2.id
    @user.id

    user_set = Set.new
    user_set << @user
    user_set << @user2

    result = User.all

    result.kind_of?(Array).should eq true
    result.count.should eq 2
    result.to_set.should eq user_set
  end

  after(:each) do
    # Since we add to the class definition for each test, we need to undefine it so we can redeclare it next time
    User.properties.clear
    Object.send(:remove_const, :User)
  end
end

