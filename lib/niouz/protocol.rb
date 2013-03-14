module Niouz
  class Protocol
    #parses input and dispatches to session
    def initialize(session,socket=nil)
      @session=session
      @socket=socket
      greet
    end

    def dispatch(req)
      case req
        when /^GROUP\s+(.+)$/i then
          putline @session.group($1)
        when /^NEXT$/i then
          putline @session.next
        when /^LAST$/i then
          putline @session.previous
        when /^MODE\s+READER/i then
          putline @session.mode_reader
        when /^SLAVE$/i then
          putline @session.slave
        when /^IHAVE\s*/i then
          putline @session.ihave
        when /^DATE$/i
          putline @session.date
        when /^HELP$/i
          putline @session.help
        when /^LIST$/i
          putline @session.list #don't escape dots
        when /^LIST\s+OVERVIEW\.FMT$/i
          putline @session.overview
        when /^XOVER(\s+\d+)?(-)?(\d+)?$/i
          putline @session.xover($1, $2, $3)
        when /^NEWGROUPS\s+(\d{6})\s+(\d{6})(\s+GMT)?(\s+<.+>)?$/i
          time = read_time($1, $2, $3)
          distribs = read_distribs($4)
          putline @session.newsgroups(time, distribs)
        when /^NEWNEWS\s+(.*)\s+(\d{6})\s+(\d{6})(\s+GMT)?\s+(<.+>)?$/i
          groups = $1.split(/\s*,\s*/)
          time = read_time($2, $3, $4)
          distribs = read_distribs($5)
          putline @session.newnews(groups, time, distribs)
        when /^(ARTICLE|HEAD|BODY|STAT)\s+<(.*)>$/i
          putline @session.article($1, $2, nil)
        when /^(ARTICLE|HEAD|BODY|STAT)(\s+\d+)?$/i
          pos = ($2 ? $2.to_i : nil)
          putline @session.article($1, nil, pos)
        when /^POST$/i # Article posting
          putline '340 Send article to be posted'
          raw_article = getlong
          putline @session.post(raw_article)
        when /^QUIT$/i # Session end
          putline "205 closing connection - goodbye!"
          :close
        else
          putline "500 command not supported"
      end
    end


    private

    # Sends a single-line response to the client
    def putline(line)
      @socket.write("#{line.chomp}\r\n")  if @socket
    end

    # Reads a multi-line message from a client (normally an
    # article being posted).

    def getlong
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

    def read_time(date, time, gmt)
      year, month, day = parse_pairs(date)
      year += (year > 50) ? 1900 : 2000
      hour, min, sec = parse_pairs(time)
      if gmt =~ /GMT/i
        return Time.gm(year, month, day, hour, min, sec)
      else
        return Time.local(year, month, day, hour, min, sec)
      end
    end

    def parse_pairs(str)
      return [str[0...2].to_i, str[2...4].to_i, str[4...6].to_i]
    end

    def read_distribs(dist)
      dist ? dist.strip.delete('<> ').split(/,/) : nil
    end

    def greet
      putline "200 server ready (#{PROG_NAME} -- #{PROG_VERSION})"
    end
  end
end