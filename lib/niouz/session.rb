module Niouz
  class Session

    def initialize(storage)
      @storage=storage
      @group=nil
      @article=nil
    end
    include CoreCommands
    include AuthCommands

    def unknown
      r(500)
    end

    private
    def move_article_pointer(direction)
      if @group.nil?
        r(412)
      elsif @article.nil?
        r(420)
      else
        # HACK: depends on method names
        article = @group.send((direction.to_s + '_article').intern, @article)
        if article
          @article = article
          mid = @group[@article].mid
          r(223, nil, "#@article #{mid} article retrieved: request text separately")
        else
          r(422, nil, "no #{direction} article in this newsgroup")
        end
      end
    end


    def send_article_part(article, nb, part)
      code, method = case part
                       when /ARTICLE/i then
                         ['220', :content]
                       when /HEAD/i then
                         ['221', :head]
                       when /BODY/i then
                         ['222', :body]
                       when /STAT/i then
                         ['223', nil]
                     end
      resp = ""
      resp << encodelong(article.send(method)) if method
      r(code, resp, "#{code} #{nb} #{article.mid} article retrieved")
    end


    # Sends a multi-line response (for example an article body)
    # to the client.
    def encodelong(content)
      content.lines.map do |line|
        dot_escape(line)
      end.join
    end

    def dot_escape(str)
      str.sub(/^\./, '..')
    end

    def r(code, body=nil, code_msg=nil)
      body=body.join("\n") if body.kind_of?(Array)
      [code, body, code_msg || Niouz::Status.msg(code)]
    end
  end
end