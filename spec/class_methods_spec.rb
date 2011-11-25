require 'spec_helper'

describe "RedisRecord model class methods" do
  before(:all) do
  end

  before(:each) do
    class TestClass < RedisRecord::Base
#      include RedisRecord
    end

    @test = TestClass.new

    @redis_mock = mock(Redis)
    RedisRecord::Backend::redis_server = @redis_mock
  end

  it "should allow a property to be declared" do
    TestClass.property :name
    TestClass.properties.include?(:name).should eq true
  end

  it "should use a custom redis instance if one is declared" do
    TestClass.redis.should eq @redis_mock
  end

  it "should create a getter when a property is declared" do
    @test.respond_to?(:name).should eq false
    TestClass.property :name
    @test.respond_to?(:name).should eq true
  end

  it "should create a setter when a property is declared" do
    @test.respond_to?(:name=).should eq false
    TestClass.property :name
    @test.respond_to?(:name=).should eq true
  end

  it "should be searchable by id" do
    @redis_mock.should_receive(:get).with("test_class:id:4").and_return(4)
    
    result = TestClass.find(4)
    result.id.should eq 4
  end

  it "should be able to retrieve all objects" do
    arr = (1..2).to_a
    @redis_mock.should_receive(:lrange).with("test_class:all", 0, -1).and_return(arr)

    result = TestClass.all

    result.count.should eq 2
    result[0].id.should eq 1
    result[1].id.should eq 2
  end

  after(:each) do
    # Since we add to the class definition for each test, we need to undefine it so we can redeclare it next time
    TestClass.properties.clear
    Object.send(:remove_const, :TestClass)
  end
end

