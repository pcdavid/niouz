module Niouz
  #based on http://tools.ietf.org/html/rfc3977
  module CoreCommands
    def capabilities # http://tools.ietf.org/html/rfc3977#section-3.3.2
                     #statedependent!
      r(101, ["VERSION 2", "READER", "NEWNEWS", "POST", "LIST" ,"AUTHINFO USER"])
                     #IHAVE,HDR,OVER IMPLEMENTATION, MODE-READER, STARTTLS , STREAMING, VERSION
      ##AUTHINFO USER only if session is secured AUTHINFO SASL first
    end

    def greet # http://tools.ietf.org/html/rfc3977#section-5.1.1
              #200,201,400,502
      r(200, nil, "server ready (#{PROG_NAME} -- #{PROG_VERSION})")
    end

#article http://tools.ietf.org/html/rfc3977#section-6.2.1
#head http://tools.ietf.org/html/rfc3977#section-6.2.2
#body http://tools.ietf.org/html/rfc3977#section-6.2.2
#stat http://tools.ietf.org/html/rfc3977#section-6.2.4
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
              r(420)
            else
              send_article_part(@article, nil, part)
          end
      end
    end

    def post_pre
      r(340) #or 440
    end

#http://tools.ietf.org/html/rfc3977#section-6.3.1
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

#http://tools.ietf.org/html/rfc3977#section-7.4
    def newnews(wildmat, time, distribs)
      resp = []
      @storage.each_article do |article|
        if article.existed_at?(time) and article.matches_groups?(wildmat) and
            @storage.groups_of(article).any? { |g| g.matches_distribs?(distribs) }
          resp << dot_escape(article.mid)
        end
      end
      r(230, resp)
    end

# http://tools.ietf.org/html/rfc3977#section-8.5
#def hdr
#end

# http://tools.ietf.org/html/rfc3977#section-6.1.2
#def listgroup
#end

#http://tools.ietf.org/html/rfc3977#section-8.3
#def over
#end

#http://tools.ietf.org/html/rfc3977#section-7.6.1
    def list
      resp =[]
      @storage.each_group { |group| resp << group.metadata }
      r(215, resp)
    end

#http://tools.ietf.org/html/rfc3977#section-7.6.6
    def list_newsgroups
      resp =[]
      @storage.each_group { |group| resp << "#{group.name} #{group.description.gsub(/\n/, "-")}" }
      r(215, resp)
    end

#http://tools.ietf.org/html/rfc3977#section-8.4
    def list_overview
      if Article::OVERVIEW_FMT
        r(215, Article::OVERVIEW_FMT.map { |header| header + ":" })
      else
        r(503)
      end
    end

# http://tools.ietf.org/html/rfc3977#section-8.6
# def list_headers
# end

#ACTIVE.TIMES,DISTRIB.PATS,HEADERS,NEWSGROUPS

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
          r(224, articles.map do |nb|
            "#{nb}\t#{@group[nb].overview}"
          end)
        end
      end
    end

#http://tools.ietf.org/html/rfc3977 #section-7.3
    def newgroups(time, distribs)
      resp= []
      @storage.each_group do |group|
        resp << group.metadata if group.existed_at?(time) and group.matches_distribs?(distribs)
      end
      r(231, resp)
    end

#http://tools.ietf.org/html/rfc3977#section-7.2
    def help
      r(100,
        ["Private news server", "Call admin to create new newsgroups"])
    end

#http://tools.ietf.org/html/rfc3977#section-7.1
    def date
      r(111, nil, Time.now.gmtime.strftime("%Y%m%d%H%M%S"))
    end

#http://tools.ietf.org/html/rfc3977#section-6.3.2
    def ihave
      r(435)
    end

#http://tools.ietf.org/html/rfc3977#section-6.1.4
    def next
      move_article_pointer(:next)
    end

#http://tools.ietf.org/html/rfc3977#section-6.1.3
    def last
      move_article_pointer(:previous)
    end

    def slave
      r(202)
    end

# http://tools.ietf.org/html/rfc3977#section-5.3
# possible responses: 200,201,502
    def mode_reader
      r(200)
    end

#http://tools.ietf.org/html/rfc3977#section-6.1.1
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

# http://tools.ietf.org/html/rfc3977#section-5.4
    def quit
      r(205)
    end

  end
end