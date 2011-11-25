require 'spec_helper'

describe "RedisRecord model instance methods" do
  before(:all) do
  end

  before(:each) do
    class TestClass
      include RedisRecord

      property :name
    end
    @test = TestClass.new

    @redis_mock = mock(Redis)
    RedisRecord::Backend::redis_server = @redis_mock
  end

  it "should have an immutable id" do
    lambda {@test.id = 4}.should raise_error NoMethodError, /protected method `id='/
  end

  it "should use a custom redis instance if one is declared" do
    @test.redis.should eq @redis_mock
  end

  it "should be able to set a property" do
    @redis_mock.should_receive(:hset).with("test_class:id:3:hash", :name, "Test Name")
    @test.send(:id=, 3)

    @test.name = "Test Name"
  end

  it "should be able to get a property" do
    @redis_mock.should_receive(:hget).with("test_class:id:3:hash", :name).and_return("Test Name")
    @test.send(:id=, 3)

    @test.name.should eq "Test Name"
  end

  after(:each) do
    # Since we add to the class definition for each test, we need to undefine it so we can redeclare it next time
    TestClass.properties.clear
    Object.send(:remove_const, :TestClass)
  end
end
