require 'spec_helper'

describe "RedisRecord model instance methods" do
  before(:all) do
  end

  before(:each) do
    class TestClass < RedisRecord::Base
      property :name
    end
    @test = TestClass.new
  end

  it "should raise an error when someone tries to change the id" do
    lambda {@test.id = 4}.should raise_error NoMethodError, /protected method `id='/
  end

  it "should use a custom redis instance if one is declared" do
    @test.redis.should eq @redis_mock
  end

  it "should be able to set a property" do
    @test.send(:id=, 3)

    @test.name = "name"
    @test.name.should eq "name"
  end

  it "should be able to get a property" do
    @redis_mock.hset "test_class:id:3:hash", :name, "name"
    @test.send(:id=, 3)

    @test.name.should eq "name"
  end

  after(:each) do
    # Since we add to the class definition for each test, we need to undefine it so we can redeclare it next time
    TestClass.properties.clear
    Object.send(:remove_const, :TestClass)
  end
end
