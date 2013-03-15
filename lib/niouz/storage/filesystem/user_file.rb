module Niouz
  module Storage
    module Filesystem
      #reads and caches filesystem db
      class UserFile
        def self.load(filename)
          File.open(filename) do |file|
            read(file)
          end
        end

        #parses input:
        #Username: user1
        #Name: Prof. Dr. First Lastname
        #Password: plain password
        #EMail: emailadress
        def self.read(io)
          @users = {}
          while u = Niouz::Rfc822Parser.parse_header_to_sym(io)
            @users[u[:username]] = User.new(u)
          end
          @users
        end

        #returns hash of users by username
        def self.by_username(name)
          @users ||= {}
          @users[name]
        end
      end
    end
  end
end