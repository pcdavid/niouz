# -*- ruby -*-
require 'socket'
require 'thread'
require 'time'
begin
  require 'md5'
rescue LoadError => e
  require 'digest/md5'
  MD5 = Digest::MD5
end
require 'gserver'

module Niouz
  PROG_NAME = 'niouz'
  PROG_VERSION  = '0.5'

  # Format of the overview "database", as an ordered list of header
  # names. See RCF 2980, Sections 2.1.7 ("LIST OVERVIEW.FMT") & 2.8
  # ("XOVER").
  OVERVIEW_FMT = [
    'Subject', 'From', 'Date', 'Message-ID', 'References', 'Bytes', 'Lines'
  ]

  # Parses the headers of a mail or news article formatted using the
  # RFC822 format. This function does not interpret the headers values,
  # but considers them free-form text. Headers are returned in a Hash
  # mapping header names to values. Ordering is lost. Continuation lines
  # are supported. An exception is raised if a header is given multiple
  # definitions, or if the format does not follow RFC822. Parsing stops
  # when encountering the end of +input+ or an empty line.
  def self.parse_rfc822_header(input)
    headers = Hash.new
    previous = nil
    input.each_line do |line|
      line = line.chomp
      break if line.empty?     # Stop at first blank line
      case line
      when /^([^: \t]+):\s+(.*)$/
        raise "Multiple definitions of header '#{$1}'." if headers.has_key?($1)
        headers[previous = $1] = $2
      when /^\s+(.*)$/
        if not previous.nil? and headers.has_key?(previous)
          headers[previous] << "\n" + $1.lstrip
        else
          raise "Invalid header continuation."
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

require 'niouz/article'
require 'niouz/newsgroup'
require 'niouz/storage'
require 'niouz/server'
