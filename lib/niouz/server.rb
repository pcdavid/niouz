# -*- ruby -*-

module Niouz
  class NNTPServer < GServer
    DEFAULT_PORT = 119

    attr_accessor :store

    def initialize(port = 119, host = GServer::DEFAULT_HOST)
      super(port, host, Float::MAX, $stderr, true)
    end

    def serve(sock)
      NNTPSession.new(sock, @store).serve
    end
  end

  class NNTPSession
    def initialize(socket, storage)
      @socket, @storage = socket, storage
      @group = nil
      @article = nil
    end

    def close
      @socket.close
    end

    # Sends a single-line response to the client
    def putline(line)
      @socket.write("#{line.chomp}\r\n")
    end

    # Sends a multi-line response (for example an article body)
    # to the client.
    def putlongresp(content)
      content.each_line do |line|
        putline line.sub(/^\./, '..')
      end
      putline '.'
    end

    # Reads a single line from the client and returns it.
    def getline
      return @socket.gets
    end

    # Reads a multi-line message from a client (normally an
    # article being posted).
    def getarticle
      lines = []
      while true
        line, char = '', nil
        while char != "\n"
          line << (char = @socket.recv(1))
        end
        line.chomp!
        break if line == '.'
        line = line[1..-1] if line.to_s[0...2] == '..'
        lines << line
      end
      return lines.join("\n")
    end

    def select_group(name)
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

    def parse_pairs(str)
      return [ str[0...2].to_i, str[2...4].to_i, str[4...6].to_i ]
    end

    def read_time(date, time, gmt)
      year, month, day = parse_pairs(date)
      year += ( year > 50 ) ? 1900 : 2000
      hour, min, sec = parse_pairs(time)
      if gmt =~ /GMT/i
        return Time.gm(year, month, day, hour, min, sec)
      else
        return Time.local(year, month, day, hour, min, sec)
      end
    end

    def send_article_part(article, nb, part)
      code, method = case part
                     when /ARTICLE/i then [ '220', :content ]
                     when /HEAD/i    then [ '221', :head ]
                     when /BODY/i    then [ '222', :body ]
                     when /STAT/i    then [ '223', nil ]
                     end
      putline "#{code} #{nb} #{article.mid} article retrieved"
      putlongresp article.send(method) if method
    end

    def overview(n, article)
      return n.to_s + "\t" + article.overview
    end

    def serve
      putline "200 server ready (#{PROG_NAME} -- #{PROG_VERSION})"
      while (request = getline)
        case request.strip
        when /^GROUP\s+(.+)$/i then putline select_group($1)
        when /^NEXT$/i         then putline move_article_pointer(:next)
        when /^LAST$/i         then putline move_article_pointer(:previous)
        when /^MODE\s+READER/i then putline '200 reader status acknowledged'
        when /^SLAVE$/i        then putline '202 slave status acknowledged'
        when /^IHAVE\s*/i      then putline '435 article not wanted - do not send it'
        when /^DATE$/i
          putline '111 ' + Time.now.gmtime.strftime("%Y%m%d%H%M%S")
        when /^HELP$/i
          putline "100 help text follows"
          putline "."

        when /^LIST$/i
          putline "215 list of newsgroups follows"
          @storage.each_group { |group| putline group.metadata }
          putline "."

        when /^LIST\s+OVERVIEW\.FMT$/i
          if OVERVIEW_FMT
            putline '215 order of fields in overview database'
            OVERVIEW_FMT.each { |header| putline header + ':' }
            putline "."
          else
            putline '503 program error, function not performed'
          end

        when /^XOVER(\s+\d+)?(-)?(\d+)?$/i
          if @group.nil?
            putline '412 no news group currently selected'
          else
            if not $1    then articles = [ @article ]
            elsif not $2 then articles = [ $1.to_i ]
            else
              last = ($3 ? $3.to_i : @group.last)
              articles = ($1.to_i .. last).select { |n| @group.has_article?(n) }
            end
            if articles.compact.empty? or articles == [ 0 ]
              putline '420 no article(s) selected'
            else
              putline '224 Overview information follows'
              articles.each do |nb|
                putline(nb.to_s + "\t" + @group[nb].overview)
              end
              putline '.'
            end
          end

        when /^NEWGROUPS\s+(\d{6})\s+(\d{6})(\s+GMT)?(\s+<.+>)?$/i
          time = read_time($1, $2, $3)
          distribs = ( $4 ? $4.strip.delete('<> ').split(/,/) : nil )
          putline "231 list of new newsgroups follows"
          @storage.each_group do |group|
            if group.existed_at?(time) and group.matches_distribs?(distribs)
              putline group.metadata
            end
          end
          putline "."

        when /^NEWNEWS\s+(.*)\s+(\d{6})\s+(\d{6})(\s+GMT)?\s+(<.+>)?$/i
          groups = $1.split(/\s*,\s*/)
          time = read_time($2, $3, $4)
          distribs = ( $5 ? $5.strip.delete('<> ').split(/,/) : nil )
          putline "230 list of new articles by message-id follows"
          @storage.each_article do |article|
            if article.existed_at?(time) and article.matches_groups?(groups) and
                @storage.groups_of(article).any? { |g| g.matches_distribs?(distribs) }
              putline article.mid.sub(/^\./, '..')
            end
          end
          putline "."

        when /^(ARTICLE|HEAD|BODY|STAT)\s+<(.*)>$/i
          article = @storage.article($2)
          if article.nil?
            putline "430 no such article found"
          else
            send_article_part(article, nil, $1)
          end

        when /^(ARTICLE|HEAD|BODY|STAT)(\s+\d+)?$/i
          nb = ($2 ? $2.to_i : @article )
          if @group.nil?
            putline '412 no newsgroup has been selected'
          elsif not @group.has_article?(nb)
            putline '423 no such article number in this group'
          else
            article = @group[@article = nb]
            send_article_part(article, @article, $1)
          end

        when /^POST$/i         # Article posting
          putline '340 Send article to be posted'
          article = getarticle
          head = Niouz.parse_rfc822_header(article)
          if not head.has_key?('Message-ID')
            article = "Message-ID: #{@storage.gen_uid}\n" + article
          end
          if not head.has_key?('Date')
            article = "Date: #{Time.now}\n" + article
          end
          if @storage.create_article(article)
            putline '240 Article received ok'
          else
            putline '441 Posting failed'
          end

        when /^QUIT$/i         # Session end
          putline "205 closing connection - goodbye!"
          close
          return

        else
          putline "500 command not supported"
        end
      end
    end
  end

end
