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

        attr_accessor :users, :articles, :newsgroups

        def load_users
          users_filename=File.join(@dir, 'users')
          if File.exist?(users_filename)
            @logger.info("[SERVER] found user file authentication enabled")
          else
            users_filename=nil
          end
          User.storage=UserFile.init(users_filename)
          self.users =  User
        end

        # Parses the newsgroups description file.
        def load_groups
          groups_filename=File.open(File.join(@dir, 'newsgroups'))
          if File.exist?(groups_filename)
            nf=NewsgroupFile.init(groups_filename)
            @logger.debug("[SERVER] newsgroup file found")
          else
            @logger.error("[SERVER] newsgroup file not found")
            raise "newsgroup file not found"
          end
          Newsgroup.storage=nf
          self.newsgroups=Newsgroup
        end

        def load_articles
          groups_filename=File.open(@dir)
          Article.storage=ArticleFile.init(groups_filename)
          self.articles=Article
        end
      end
    end
  end
end