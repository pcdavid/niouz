module Niouz
  module Storage
    # This class manages the "database" of groups and articles.
    module Filesystem
      class Storage
        def self.init(logger, options={})
          new(logger, options[:dir])
        end

        def initialize(logger, dir)
          @dir=dir
          @logger=logger
          load_users
          load_groups
          load_articles
        end


        def load_users
          users_filename=File.join(@dir, 'users')
          if File.exist?(users_filename)
            UserFile.load(users_filename)
            @logger.info("[SERVER] found user file authentication enabled")
          end
          User.storage=UserFile

        end

        # Parses the newsgroups description file.
        def load_groups
          groups_filename=File.open(File.join(@dir, 'newsgroups'))
          if File.exist?(groups_filename)
            GroupFile.load(groups_filename)
            @logger.debug("[SERVER] newsgroup file found")
          else
            @logger.error("[SERVER] newsgroup file not found")
            raise "newsgroup file not found"
          end
          Newsgroup.storage=GroupFile
        end

        def load_articles
          groups_filename=File.open(@dir)
          ArticleFile.load(groups_filename)

          Article.storage=ArticleFile
        end
      end
    end
  end
end