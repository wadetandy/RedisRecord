require 'spec_helper'

describe RedisRecord::Base do
  it_should_behave_like "ActiveModel"

  context "Validations" do
    before(:each) do
      class User < RedisRecord::Base
      end

      @user = User.new
    end

    it "should allow basic validations to be declared" do
      class User < RedisRecord::Base
        property :name

        validates :name, :presence => true
      end

      @user.valid?.should eq false
      @user.errors[:name].any?.should eq true
      @user.name = "name"
      @user.valid?.should eq true
      @user.errors[:name].any?.should eq false
    end

    it "should set error messages on validation errors" do
      class User < RedisRecord::Base
        property :size

        validates :size, :inclusion => { :in => %w(small medium large), :message => "%{value} is not a valid size"}
      end

      @user.size = "tiny"
      @user.valid?.should eq false
      @user.errors[:size][0].should eq "tiny is not a valid size"

      @user.size = "small"
      @user.valid?.should eq true
    end

    after(:each) do
      User.properties.clear
      Object.send(:remove_const, :User)
    end
  end

  context "Mass Assignment Security" do
    before(:each) do
      class User < RedisRecord::Base
        property :name
        property :email
        property :is_admin
      end

      @user = User.new
    end

    it "should default to all attributes being mass-assignable" do
      @user.attributes = {:name => "Fred", :email => "freddie.murcury@gmail.com", :is_admin => true}

      @user.name.should eq "Fred"
      @user.email.should eq "freddie.murcury@gmail.com"
      @user.is_admin.should eq "true"
    end

    it "should prevent mass-assigning attributes that are no declared accessible" do
      User.attr_accessible :name, :email
      @user.attributes = {:name => "Fred", :email => "freddie.murcury@gmail.com", :is_admin => true}

      @user.name.should eq "Fred"
      @user.email.should eq "freddie.murcury@gmail.com"
      @user.is_admin.should eq nil
      
      User.accessible_attributes.to_set.should eq ["name", "email"].to_set
    end

    it "should allow elevated mass-assignable roles to be declared" do
      User.attr_accessible :name
      User.attr_accessible :email, :as => :admin
      @user.attributes = {:name => "Fred", :email => "freddie.murcury@gmail.com"}

      @user.name.should eq "Fred"
      @user.email.should eq nil

      @user.assign_attributes({:email => "freddie.murcury@gmail.com"}, :as => :admin)
      @user.email.should eq "freddie.murcury@gmail.com"
    end

    it "should not mass-assign attributes that are declared as attr_protected" do
      User.attr_protected :is_admin

      @user.is_admin = false
      @user.attributes = { :name => "Fred", :is_admin => true }
      @user.name.should eq "Fred"
      @user.is_admin.should eq "false"
    end

    after(:each) do
      User.properties.clear
      Object.send(:remove_const, :User)
    end
  end
end
