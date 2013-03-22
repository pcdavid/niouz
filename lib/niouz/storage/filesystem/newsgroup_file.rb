module Niouz
  module Storage
    module Filesystem
      #reads and caches filesystem db
      class NewsgroupFile
        def self.init(filename)
          nf=new
          File.open(filename) do |file|
            nf.read(file)
          end
          nf
        end

        def initialize
          @models = {}
        end

        #parses input:
        def read(io)
          @models = {}
          while m = Niouz::Rfc822Parser.parse_header_to_sym(io)
             m[:date_created] = Niouz::Rfc822Parser.parse_date(m[:date_created])
            @models[m[:name]] = Newsgroup.new(m)
          end
          @models
        end

        def all
          @models.values
        end

        #returns hash of users by username
        def by_name(name)
          @models[name]
        end

      end
    end
  end
end