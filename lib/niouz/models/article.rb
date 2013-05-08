module Niouz
  module Models
    module Article
      #class has to implement
      #create_from_content(content)
      #find_each
      #newnews(wildmat,time,distribs)
      #find_message_by_id(message_id)

      #instance has to implement
      #attributes: message_id, date, overview, newsgroup_names, filename
      #assocs: groups

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

      end

      #when content is set we don't store it, just extract the stuff we need
      def content=(_content)
        news=Niouz::Rfc822Parser.new(_content)
        self.message_id= news.message_id
        self.newsgroup_names = news.newsgroup_names
        self.date = news.date
        self.overview= news.to_overview(OVERVIEW_FMT)
      end

      def mid
        message_id
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
end