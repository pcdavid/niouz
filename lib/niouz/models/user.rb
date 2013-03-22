module Niouz
  module Models
    module User
      #class has to implement

      #instance has to implement
      #attributes: name,username,email,password


      def guest?
        username=='guest'
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def auth(username, passwd)
          return nil if passwd.nil? || passwd.empty?
          user=find_by_username(username)
          if user.password==passwd
            user
          else
            nil
          end
        end

        def guest
          @guest ||= new(:username => 'guest')
        end
      end
    end
  end
end