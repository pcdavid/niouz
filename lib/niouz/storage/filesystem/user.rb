module Niouz
  module Storage
    module Filesystem
      class User

        include Model
        include Models::User

        attr_accessor :name, :username, :email, :password

        def self.find_by_username(username)
          storage.by_username(username) || User.guest
        end

      end
    end
  end
end
