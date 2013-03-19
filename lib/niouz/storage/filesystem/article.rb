module Niouz
  module Storage
    module Filesystem

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
      class Article

        include Model
        include Models::Article
        #filestore specific
        def self.find_by_message_id(mid)
          return storage.by_message_id(mid)
        end

        #select all article matching groups, wildmats and time
        def self.newnews(wildmat, time, distribs)
          storage.all.select do |article|
            article.existed_at?(time) &&
                article.matches_groups?(wildmat) &&
                article.newsgroups.any? { |g| g.matches_distribs?(distribs) }
          end
        end

        def self.find_each
          raise "TODO"
          articles = @lock.synchronize { articles.dup }
          articles.each { |art| yield(art) }

          storage.all.each do |grp|
            yield
          end
        end

        def self.create_from_content(content)
          news = Niouz::Rfc822Parser.new(content, true)
          article=new(:content => news.content) #article does not store the content!
          storage.save(article, content)
          article
        end

        def newsgroups
          newsgroup_names.map { |name| Newsgroup.find_by_name(name) }
        end

        # The message identifer.
        attr_accessor :message_id


        # The list of newsgroups (names) this article is in.
        attr_accessor :newsgroup_names

        # Overview of this article (see OVERVIEW_FMT).
        attr_accessor :overview

        attr_accessor :id

        attr_accessor :date

        attr_accessor :filename

      end
    end

  end
end
