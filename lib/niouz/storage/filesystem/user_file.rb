module Niouz
  module Storage
    module Filesystem
      #reads and caches filesystem db
      class UserFile
        def self.init(filename)
          uf=new
          if filename
            File.open(filename) do |file|
              uf.read(file)
            end
          end
          uf
        end

        def initialize
          @users={}
        end

        #parses input:
        #Username: user1
        #Name: Prof. Dr. First Lastname
        #Password: plain password
        #EMail: emailadress
        def read(io)
          @users = {}
          while u = Niouz::Rfc822Parser.parse_header_to_sym(io)
            @users[u[:username]] = User.new(u)
          end
          @users
        end

        #returns hash of users by username
        def by_username(name)
          @users[name]
        end


      end
    end
  end
end