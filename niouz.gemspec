# -*- ruby -*-
require 'rubygems'

spec = Gem::Specification.new do |spec|
  spec.name = 'niouz'
  spec.version = '0.7.0'
  spec.summary = 'A small NNTP server..'
  spec.description = %{niouz is a small, simple NNTP server suitable to set up private newsgroups for an intranet or workgroup.}
  spec.author = 'Pierre-Charles David'
  spec.email = 'pcdavid@gmail.com'
  spec.homepage = 'http://github.com/pcdavid/niouz'

  spec.executables = [ 'niouz' ]
  spec.files = Dir['lib/**/*.rb'] + Dir['bin/niouz']
  spec.has_rdoc = false
end
