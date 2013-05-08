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
  PROG_VERSION = '0.7'
  # Format of the overview "database", as an ordered list of header
  # names. See RCF 2980, Sections 2.1.7 ("LIST OVERVIEW.FMT") & 2.8
  # ("XOVER").
  OVERVIEW_FMT = [
      'Subject', 'From', 'Date', 'Message-ID', 'References', 'Bytes', 'Lines'
  ]

end

require 'logger'

require 'niouz/rfc822_parser'
require 'niouz/status'

require 'niouz/core_commands'
require 'niouz/auth_commands'
require 'niouz/session'
require 'niouz/protocol'
require 'niouz/server'

#models
require 'niouz/models/user'
require 'niouz/models/article'
require 'niouz/models/newsgroup'

