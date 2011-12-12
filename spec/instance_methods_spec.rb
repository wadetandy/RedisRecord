require 'spec_helper'

describe "RedisRecord model instance methods" do
  before(:all) do
  end

  before(:each) do
    class User < RedisRecord::Base
      property :name
      property :email
    end
    @user = User.new
  end

  it "should mass-assign attributes passed to the constructor" do
    @user = User.new :name => "Harry", :email => "harry.burns@gmail.com"
    @user.name.should eq "Harry"
    @user.email.should eq "harry.burns@gmail.com"
  end

  it "should have a mass-assignment setter" do  
    @user.attributes = {:name => "Harry", :email => "harry.burns@gmail.com"}
    @user.name.should eq "Harry"
    @user.email.should eq "harry.burns@gmail.com"
  end

  it "should be able to mass-assign attributes" do
    @user.assign_attributes :name => "Harry", :email => "harry.burns@gmail.com"
    @user.name.should eq "Harry"
    @user.email.should eq "harry.burns@gmail.com"
  end

  it "should be able to query whether an attribute is set" do
    @user.attribute_present?(:name).should eq false
    @user.name = "Harry"    
    @user.attribute_present?(:name).should eq true
  end

  it "should raise an error if an invalid property is mass-assigned" do
    lambda {@user.assign_attributes(:address => "123 Main St.")}.should raise_error RedisRecord::Exceptions::UnknownAttribute
  end

  it "should be able to query for all attribute names" do
    @user.attribute_names.to_set.should eq [:email, :name].to_set
  end

  it "should be able query if single attribute exists" do
    @user.has_attribute?(:name).should eq true    
    @user.has_attribute?(:non_existant).should eq false
  end

  it "should raise an error when someone tries to change the id" do
    lambda {@user.id = 4}.should raise_error NoMethodError, /protected method `id='/
  end

  it "should use a custom redis instance if one is declared" do
    @user.redis.should eq @redis_mock
  end

  it "should be able to set a property" do
    @user.send(:id=, 3)

    @user.name = "name"
    @user.name.should eq "name"
  end

  it "should be able to get a property" do
    @redis_mock.hset "user:id:3:hash", :name, "name"
    @user.send(:id=, 3)

    @user.name.should eq "name"
  end

  it "should be able to test for equality" do
    @user2 = User.new
    
    @user.send("id=", 1)
    @user2.send("id=", 2)
    @user.==(@user2).should eq false

    @user2.send("id=", 1)
    @user.==(@user2).should eq true

    str_val = "sample string"
    @user.==(str_val).should eq false
  end

  after(:each) do
    # Since we add to the class definition for each test, we need to undefine it so we can redeclare it next time
    User.properties.clear
    Object.send(:remove_const, :User)
  end
end
