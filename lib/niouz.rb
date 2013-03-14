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


end

require 'niouz/rfc822_parser'
require 'niouz/article'
require 'niouz/newsgroup'
require 'niouz/storage'
require 'niouz/server'
