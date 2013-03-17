module Niouz
  class Rfc822Parser
    class ParsingError < StandardError;
    end

    def self.parse_header(input)

      # Parses the headers of a mail or news article formatted using the
      # RFC822 format. This function does not interpret the headers values,
      # but considers them free-form text. Headers are returned in a Hash
      # mapping header names to values. Ordering is lost. Continuation lines
      # are supported. An exception is raised if a header is given multiple
      # definitions, or if the format does not follow RFC822. Parsing stops
      # when encountering the end of +input+ or an empty line.

      headers = Hash.new
      previous = nil
      input.each_line do |line|
        line = line.chomp
        break if line.empty? # Stop at first blank line
        case line
          when /^([^: \t]+):\s+(.*)$/
            raise ParsingError.new("Multiple definitions of header: '#{$1}'.") if headers.has_key?($1)
            previous = $1
            headers[$1] = $2
          when /^\s+(.*)$/
            if not previous.nil? and headers.has_key?(previous)
              headers[previous] << "\n" + $1.lstrip
            else
              raise ParsingError.new("Invalid header continuation: '#{$1}'")
            end
          else
            raise "Invalid header format."
        end
      end
      return headers.empty? ? nil : headers
    end

    def self.parse_header_to_sym(input)
      headers=parse_header(input)
      return unless headers
      new_headers={}
      headers.each_pair do |key, value|
        n_key=key.downcase.gsub("-", "_").to_sym
        new_headers[n_key]=value
      end
      new_headers
    end

    # Utility to parse dates
    def self.parse_date(aString)
      return Time.rfc822(aString) rescue Time.parse(aString)
    end

    def initialize(content, fix=false)
      @content=content

      if fix #fix if news is not correct
        unless has_message_id?
          uid=MD5.hexdigest(Time.now.to_s) + "@" + Socket.gethostname #perhaps sth configurable?
          self.message_id = uid
        end
        self.date=Time.now unless has_date?
      end
    end

    attr_reader :content

    def message_id
      return @message_id if defined?(@message_id)
      if headers['Message-ID'] =~ /<([^>]+)>/
        @message_id= $1
      else
        @message_id = nil
      end
      @message_id
    end

    def size
      content.size
    end

    def line_no
      @line_no ||= content.split("\n").size
    end

    def has_message_id?
      headers.has_key?('Message-ID')
    end

    def message_id=(msg_id)
      raise "already has a message_id" if has_message_id?
      @message_id=msg_id
      @content = "Message-ID: <#{msg_id}>\n" + @content
      nil
    end

    def has_date?
      headers.has_key?('Date')
    end

    def date=(time=Time.now)
      raise "already has a date" if has_date?
      @content = "Date: #{time}\n" + @content
    end

    def date
      if has_date?
        self.class.parse_date(headers['Date'])
      else
        nil
      end
    end

    def newsgroup_names
      headers['Newsgroups'].split(/\s*,\s*/)
    end

    def to_overview(fmt)
      fmt.collect do |h|
        headers[h] ? headers[h].gsub(/(\r\n|\n\r|\n|\t)/, ' ') : nil
      end.join("\t")
    end

    def headers
      return @headers if @headers
      @headers=self.class.parse_header(StringIO.new(content))
      @headers_sym={}
      @headers.each_pair do |key, value|
        n_key=key.downcase.gsub("-", "_").to_sym
        @headers_sym[n_key]=value
      end
      @headers['Bytes'] ||= size.to_s
      @headers['Lines'] ||= line_no.to_s
      @headers
    end

    def headers_sym
      return @headers_sym if @headers_sym
      @headers_sym={}
      headers.each_pair do |key, value|
        n_key=key.downcase.gsub("-", "_").to_sym
        @headers_sym[n_key]=value
      end
      @headers_sym
    end

    # returns the value of the header
    def header(name)
      if name.kind_of?(Symbol)
        headers_sym[name]
      else
        headers[name]
      end
    end

    def body
      lines = ''
      in_head = true
      StringIO.new(content).each_line do |line|
        if in_head && line.chomp.empty?
          in_head = false
        else
          lines << line unless in_head
        end
      end
      lines
    end

    def head
      lines = ''
      StringIO.new(content).each_line do |line|
        break if line.chomp.empty?
        lines << line
      end
      lines
    end
  end
end