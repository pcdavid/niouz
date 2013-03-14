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
    # Utility to parse dates
    def self.parse_date(aString)
      return Time.rfc822(aString) rescue Time.parse(aString)
    end

  end
end