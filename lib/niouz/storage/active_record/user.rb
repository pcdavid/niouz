module Niouz
  module Storage
    module ActiveRecord
      class User < ::ActiveRecord::Base
        include Models::User


      end
    end
  end
end
