module Niouz
  class Session


    def initialize(storage)
      @storage=storage
      @group=nil
      @article=nil
    end


    def article(part, mid, pos)
      case
        when mid
          article = @storage.article(mid)
          if article.nil?
            "430 no such article found"
          else
            send_article_part(article, nil, part)
          end
        when pos
          if @group.nil?
            '412 no newsgroup has been selected'
          else
            if @group.has_article?(pos)
              @article = @group[pos]
              send_article_part(@article, pos, part)
            else
              '423 no such article number in this group'
            end
          end
        else
          case
            when @group.nil?
              '412 no newsgroup has been selected'
            when @article.nil?
              "430 no such article found" #check if this is the right answer
            else
              send_article_part(@article, nil, part)
          end
      end
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
        '240 Article received ok'
      else
        '441 Posting failed'
      end
    end

    def newnews(groups, time, distribs)
      resp = "230 list of new articles by message-id follows\n"
      @storage.each_article do |article|
        if article.existed_at?(time) and article.matches_groups?(groups) and
            @storage.groups_of(article).any? { |g| g.matches_distribs?(distribs) }
          resp << "#{article.mid.sub(/^\./, '..')}\n"
        end
      end
      resp << "."
    end

    def overview
      if Article::OVERVIEW_FMT
        "'215 order of fields in overview database\n" +
            Article::OVERVIEW_FMT.map { |header| header + ":\n" }.join + "."
      else
        '503 program error, function not performed'
      end
    end

    #from, to
    def xover(one, two, three)
      if @group.nil?
        '412 no news group currently selected'
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
          '420 no article(s) selected'
        else
          "224 Overview information follows\n" +
              articles.map do |nb|
                "#{nb}\t#{@group[nb].overview}\n"
              end.join() + '.'
        end
      end
    end

    def neswgroups(time, distribs)

      resp="231 list of new newsgroups follows\n"
      @storage.each_group do |group|
        if group.existed_at?(time) and group.matches_distribs?(distribs)
          resp << "#{group.metadata}\n"
        end
      end
      resp << "."
    end

    def list
      resp ="215 list of newsgroups follows\n"
      @storage.each_group { |group| resp << "#{group.metadata}\n" }
      resp << "."
      resp
    end

    def help
      "100 help text follows\n"+
          "Private news server\nCall admin to create new newsgroups\n."
    end

    def date
      '111 ' + Time.now.gmtime.strftime("%Y%m%d%H%M%S")
    end

    def ihave
      '435 article not wanted - do not send it'
    end

    def next
      move_article_pointer(:next)
    end

    def previous
      move_article_pointer(:previous)
    end

    def slave
      '202 slave status acknowledged'
    end

    def mode_reader
      '200 reader status acknowledged'
    end

    def group(name)
      if @storage.has_group?(name)
        @group = @storage.group(name)
        @article = @group.first
        return "211 %d %d %d %s" % [@group.size_estimation,
                                    @group.first,
                                    @group.last,
                                    @group.name] # FIXME: sync
      else
        return '411 no such news group'
      end
    end


    def overview(n, article)
      return n.to_s + "\t" + article.overview
    end

    private
    def move_article_pointer(direction)
      if @group.nil?
        return '412 no newsgroup selected'
      elsif @article.nil?
        return '420 no current article has been selected'
      else
        # HACK: depends on method names
        article = @group.send((direction.to_s + '_article').intern, @article)
        if article
          @article = article
          mid = @group[@article].mid
          return "223 #@article #{mid} article retrieved: request text separately"
        else
          return "422 no #{direction} article in this newsgroup"
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
      resp = "#{code} #{nb} #{article.mid} article retrieved\n"
      resp << encodelong(article.send(method)) if method
      resp << "\n."
      resp
    end


    # Sends a multi-line response (for example an article body)
    # to the client.
    def encodelong(content)
      content.lines.map do |line|
        line.sub(/^\./, '..')
      end.join
    end

  end
end