module Niouz


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
    # Format of the overview "database", as an ordered list of header
    # names. See RCF 2980, Sections 2.1.7 ("LIST OVERVIEW.FMT") & 2.8
    # ("XOVER").
    OVERVIEW_FMT = [
        'Subject', 'From', 'Date', 'Message-ID', 'References', 'Bytes', 'Lines'
    ]

    include Model

    #filestore specific
    def self.find_by_message_id(mid)
      return storage.by_message_id(mid)
    end

    def self.each
      raise "TODO"
      articles = @lock.synchronize { articles.dup }
      articles.each { |art| yield(art) }

      storage.all.each do |grp|
        yield
      end
    end

    def self.create_from_content(content)
      news = Niouz::Rfc822Parser.new(content,true)
      article=new(:content => news.content) #article does not store the content!
      storage.save(article, content)
      article
    end

    def groups
      newsgroup_names.map { |name| Newsgroup.find_by_name(name) }
    end

    # The message identifer.
    attr_accessor :message_id
    alias mid message_id

    # The list of newsgroups (names) this article is in.
    attr_accessor :newsgroup_names

    # Overview of this article (see OVERVIEW_FMT).
    attr_accessor :overview

    attr_accessor :id

    attr_accessor :date

    attr_accessor :filename

    #when content is set we don't store it, just extract the stuff we need
    def content=(_content)
      news=Niouz::Rfc822Parser.new(_content)
      self.message_id= news.message_id
      self.newsgroup_names = news.newsgroup_names
      self.date = news.date
      self.overview= news.to_overview(OVERVIEW_FMT)
    end

    # Tests whether this Article already existed at the given time.
    def existed_at?(aTime)
      return date >= aTime
    end

    # Returns the head of the article, i.e. the content of the
    # associated file up to the first empty line.
    def head
      news=Niouz::Rfc822Parser.new(content)
      news.head
    end

    # Returns the body of the article, i.e. the content of the
    # associated file starting from the first empty line.
    def body
      news=Niouz::Rfc822Parser.new(content)
      news.body
    end

    # Returns the full content of the article, head and body. This is
    # simply the verbatim content of the associated file.
    def content
      return File.read(filename)
    end

    def matches_groups?(groups_specs) # TODO
                                      # See description of NEWNEWS command in RFC 977.
      return true
    end

  end
end
