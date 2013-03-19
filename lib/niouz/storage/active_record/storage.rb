module Niouz
  module Storage
    # This class manages the "database" of groups and articles.
    module ActiveRecord
      class Storage
        def self.init(logger, options={})
          new(logger, options)
        end

        def initialize(logger, options)
          @config_file=options[:config]
          pg_config_yaml = YAML.load_file(@config_file)
          pg_config_yaml.symbolize_keys!
          pg_config=pg_config_yaml[:connection]
          ::ActiveRecord::Base.establish_connection(pg_config)
          ::ActiveRecord::Base.connection.execute("SELECT 1;")
          ::ActiveRecord::Base.logger=logger
          @dir=options[:dir]
          @logger=logger
          self.users = User
          self.newsgroups=Newsgroup
          self.articles=Article
          self.article_newsgroups=ArticlesNewsgroup
        end

        attr_accessor :users, :articles, :newsgroups, :article_newsgroups
      end
    end
  end
end