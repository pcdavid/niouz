module Niouz
  class Protocol
    #parses input and dispatches to session
    def initialize(session, socket=nil)
      @session=session
      @socket=socket
      send(@session.greet) #handle 402 and 502 response (close connection)
    end

    def dispatch(req)
      out=case req
            when /^CAPABILITIES((\s+)(.+))?$/i then
              @session.capabilities($3)
            when /^GROUP\s+(.+)$/i then
              @session.group($1)
            when /^AUTHINFO USER\s+(.+)$/i then
              @session.authinfo_user($1)
            when /^AUTHINFO PASS\s+(.+)$/i then
              @session.authinfo_pass($1)
            when /^NEXT$/i then
              @session.next
            when /^LAST$/i then
              @session.last
            when /^MODE\s+READER/i then
              @session.mode_reader
            when /^SLAVE$/i then
              @session.slave
            when /^IHAVE\s*/i then
              @session.ihave
            when /^DATE$/i
              @session.date
            when /^HELP$/i
              @session.help
            when /^LIST$/i
              @session.list
            when /^LIST\s+OVERVIEW\.FMT$/i
              @session.list_overview
            when /^LIST\s+ACTIVE$/i
              @session.list_overview
            when /^LIST\s+NEWSGROUPS$/i
              @session.list_newsgroups
            when /^XOVER(\s+\d+)?(-)?(\d+)?$/i
              @session.xover($1, $2, $3)
            when /^NEWGROUPS\s+(\d{6})\s+(\d{6})(\s+GMT)?(\s+<.+>)?$/i
              time = read_time($1, $2, $3)
              distribs = read_distribs($4)
              @session.newgroups(time, distribs)
            when /^NEWNEWS\s+(.*)\s+(\d{6})\s+(\d{6})(\s+GMT)?\s+(<.+>)?$/i
              wildmat = $1.split(/\s*,\s*/)
              time = read_time($2, $3, $4)
              distribs = read_distribs($5)
              @session.newnews(wildmat, time, distribs)
            when /^(ARTICLE|HEAD|BODY|STAT)\s+<(.*)>$/i
              @session.article($1, $2, nil)
            when /^(ARTICLE|HEAD|BODY|STAT)(\s+\d+)?$/i
              pos = ($2 ? $2.to_i : nil)
              @session.article($1, nil, pos)
            when /^POST$/i # Article posting this is a twostep process
              res=@session.post_pre
              if res[0] == 340
                send(res)
                raw_article = getlong
                @session.post(raw_article)
              else
                res
              end
            when /^QUIT$/i # Session end
              @session.quit
            else
              @session.unknown
          end
      #out = [code,escaped body, code_msg]
      send(out)
      out[0]==205 ? :quit : nil
    end

    private

    def send(out)
      resp="#{out[0]} #{out[2]}\n"
      if out[1]
        resp << out[1] << "\n" unless out[1].empty?
        resp << "."
      end
      putline resp
    end

    # Sends a single-line response to the client
    def putline(line)
      @socket.write("#{line.chomp}\r\n") if @socket
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

  end
end