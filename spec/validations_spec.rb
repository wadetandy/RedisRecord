require 'spec_helper'

describe "RedisRecord Validations" do
  before(:each) do
    class TestClass < RedisRecord::Base
    end

    @test = TestClass.new
  end

  it "should allow basic validations to be declared" do
    class TestClass < RedisRecord::Base
      property :name

      validates :name, :presence => true
    end

    @test.valid?.should eq false
    @test.name = "name"
    @test.valid?.should eq true
  end

  after(:each) do
    Object.send(:remove_const, :TestClass)
  end
end
