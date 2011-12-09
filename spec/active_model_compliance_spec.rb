require 'spec_helper'

describe RedisRecord::Base do
  it_should_behave_like "ActiveModel"

  context "Validations" do
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
      @test.errors[:name].any?.should eq true
      @test.name = "name"
      @test.valid?.should eq true
      @test.errors[:name].any?.should eq false
    end

    it "should set error messages on validation errors" do
      class TestClass < RedisRecord::Base
        property :size

        validates :size, :inclusion => { :in => %w(small medium large), :message => "%{value} is not a valid size"}
      end

      @test.size = "tiny"
      @test.valid?.should eq false
      @test.errors[:size][0].should eq "tiny is not a valid size"

      @test.size = "small"
      @test.valid?.should eq true
    end

    after(:each) do
      TestClass.properties.clear
      Object.send(:remove_const, :TestClass)
    end
  end
end
