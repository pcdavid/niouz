module Niouz
  module Storage
    module Filesystem
      module Model

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def storage
            @storage
          end

          def storage=(obj)
            @storage=obj
          end
        end


        def initialize(atts)
          atts.each_pair do |key, value|
            self.send("#{key}=", value)
          end
        end

        private
        def storage
          self.class.storage
        end

      end
    end
  end
end