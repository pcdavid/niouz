module Niouz
  module Storage
    module ActiveRecord

      # Represents a news article stored as a simple text file in RFC822
      # format. Only the minimum information is kept in memory by instances
      # of this class:
      # * the message-id (+Message-ID+ header)
      # * the names of the newsgroups it is posted to (+Newsgroups+ header)
      # * the date it was posted (+Date+ header)
      # * overview data, generated on creation (see OVERVIEW_FMT)
      #
      # The rest (full header and body) are re-read from the file
      # each time it is requested.
      #
      # None of the methods in this class ever modify the content
      # of the file storing the article or the state of the instances
      # once created. Thread-safe.
      class Article < ::ActiveRecord::Base

        include Models::Article
        belongs_to :user
        has_many :articles_newsgroups
        has_many :newsgroups, :through => :articles_newsgroups
        #select all article matching groups, wildmats and time
        def self.newnews(wildmat, time, distribs)
          storage.all.select do |article|
            article.existed_at?(time) &&
                article.matches_groups?(wildmat) &&
                article.groups.any? { |g| g.matches_distribs?(distribs) }
          end
        end

        def self.create_from_content(content)
          news = Niouz::Rfc822Parser.new(content, true)
          article=new(:content => news.content) #article does not store the content!
          ::ActiveRecord::Base.transaction do
            article.save!
            article.add_to_newsgroups!
            article.save_file!(news.content)
          end
          article
        end

        alias_attribute :date, :created_at

        def add_to_newsgroups!
          newsgroup_names.each do |name|
            grp=Newsgroup.find_by_name(name)
            if grp
              grp.lock!
              grp.add_article(self)
            end
          end
        end

        def save_file!(content)
          File.open(filename, "w") do |fd|
            fd.write(content)
          end
        end

        def filename
          "articles/#{id}"
        end
      end
    end

  end
end
