require 'spec_helper'

describe Niouz::User do
  let(:input) { StringIO.new(
      "Username: user1\nPassword: passwd1\nEmail: email1\nName: name1\n")

  }

  describe "auth" do
    it "should auth a user" do
      Niouz::UserFile.read(input)
      Niouz::User.auth('user1', 'passwd1').should_not be_nil
    end
    it "should be nil if wrong password" do
      Niouz::UserFile.read(input)
      Niouz::User.auth('user1', 'passwd').should be_nil
    end

    it "should be nil if unknown user" do
      Niouz::UserFile.read(input)
      Niouz::User.auth('user', 'passwd').should be_nil
    end

    it "should fail if password is blank" do
      Niouz::User.auth('user1', '').should be_nil
      Niouz::User.auth('user1', nil).should be_nil
    end

  end

  describe "find_by_name" do
    it "should return existing users" do
      Niouz::UserFile.read(input)
      Niouz::User.find_by_username('user1').should_not be_nil
      Niouz::User.find_by_username('user1').should_not be_guest
    end
    it "should return guest if unknown" do
      Niouz::UserFile.read(input)
      Niouz::User.find_by_username('user2').should be_guest
    end

  end
  describe "guest" do
    it "should exist" do
      Niouz::User.guest.should be_kind_of(Niouz::User)
    end
  end
end