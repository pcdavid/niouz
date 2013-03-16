module Niouz
  module Storage
    module Filesystem
      #reads and caches filesystem db
      class GroupFile
        def self.load(filename)
          File.open(filename) do |file|
            read(file)
          end
        end

        #parses input:
        def self.read(io)
          @models = {}
          while m = Niouz::Rfc822Parser.parse_header_to_sym(io)
            @models[m[:name]] = Newsgroup.new(m)
          end
          @models
        end

        def self.all
          @models.values
        end

        #returns hash of users by username
        def self.by_name(name)
          @models ||= {}
          @models[name]
        end

      end
    end
  end
end