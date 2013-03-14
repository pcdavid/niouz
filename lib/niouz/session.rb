module Niouz
  class Session


    def initialize(storage)
      @storage=storage
      @group=nil
      @article=nil
    end

    def greet
      r(200, nil, "server ready (#{PROG_NAME} -- #{PROG_VERSION})")
    end

    def article(part, mid, pos)
      case
        when mid
          article = @storage.article(mid)
          if article.nil?
            r(430)
          else
            send_article_part(article, nil, part)
          end
        when pos
          if @group.nil?
            r(412)
          else
            if @group.has_article?(pos)
              @article = @group[pos]
              send_article_part(@article, pos, part)
            else
              r(423)
            end
          end
        else
          case
            when @group.nil?
              r(412)
            when @article.nil?
              r(430)
            else
              send_article_part(@article, nil, part)
          end
      end
    end

    def post_pre
      r(340)
    end

    def post(raw_article)

      head = Niouz::Rfc822Parser.parse_header(raw_article)
      if not head.has_key?('Message-ID')
        raw_article = "Message-ID: #{@storage.gen_uid}\n" + raw_article
      end
      if not head.has_key?('Date')
        raw_article = "Date: #{Time.now}\n" + raw_article
      end
      if @storage.create_article(raw_article)
        r(240)
      else
        r(441)
      end

    end

    def newnews(groups, time, distribs)
      resp = []
      @storage.each_article do |article|
        if article.existed_at?(time) and article.matches_groups?(groups) and
            @storage.groups_of(article).any? { |g| g.matches_distribs?(distribs) }
          resp << dot_escape(article.mid)
        end
      end
      r(230, resp)
    end

    def list_overview
      if Article::OVERVIEW_FMT
        r(215, Article::OVERVIEW_FMT.map { |header| header + ":" })
      else
        r(503)
      end
    end

    #from, to
    def xover(one, two, three)
      if @group.nil?
        r(412)
      else
        if not one then
          articles = [@article]
        elsif not two then
          articles = [one.to_i]
        else
          last = (three ? three.to_i : @group.last)
          articles = (one.to_i .. last).select { |n| @group.has_article?(n) }
        end
        if articles.compact.empty? or articles == [0]
          r(420)
        else
          r(224, articles.map do |nb| "#{nb}\t#{@group[nb].overview}" end)
        end
      end
    end

    def newgroups(time, distribs)
      resp= []
      @storage.each_group do |group|
        resp << group.metadata if group.existed_at?(time) and group.matches_distribs?(distribs)
      end
      r(231, resp)
    end

    def list
      resp =[]
      @storage.each_group { |group| resp << group.metadata }
      r(215, resp)
    end

    def help
      r(100,
        ["Private news server","Call admin to create new newsgroups"])
    end

    def date
      r(111, nil, Time.now.gmtime.strftime("%Y%m%d%H%M%S"))
    end

    def ihave
      r(435)
    end

    def next
      move_article_pointer(:next)
    end

    def last
      move_article_pointer(:previous)
    end

    def slave
      r(202)
    end

    def mode_reader
      r(200)
    end

    def group(name)
      if @storage.has_group?(name)
        @group = @storage.group(name)
        @article = @group.first
        r(211, nil, "%d %d %d %s" % [@group.size_estimation,
                                     @group.first,
                                     @group.last,
                                     @group.name]) # FIXME: sync
      else
        r(411)
      end
    end

    def quit
      r(205)
    end

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