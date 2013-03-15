module Niouz
  class User
    def initialize(atts)
      atts.each_pair do |key, value|
        self.send("#{key}=", value)
      end
    end

    attr_accessor :name, :username, :email, :password, :guest
    alias guest? guest

    #memory based
    def self.auth(username, passwd)
      return nil if passwd.nil? || passwd.empty?
      user=find_by_username(username)
      if user.password==passwd
        user
      else
        nil
      end
    end

    def self.find_by_username(username)
      UserFile.by_username(username) || User.guest
    end

    def self.guest
      @guest ||= new(:username => 'guest', :guest => true)
    end
  end
end