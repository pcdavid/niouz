module Niouz
  module Status
    STATUS = {
        100 => "help text follows",
        111 => "----date",
        200 => 'acknowledged',
        202 => 'slave status acknowledged',
        205 => "closing connection - goodbye!",
        211 => "----group answer",
        215 => "order of fields in overview database",
        220 => "article retrieved",
        221 => "article retrieved (head)",
        222 => "article retrieved (body)",
        223 => "article retrieved: request text separately",
        224 => "Overview information follows",
        231 => "list of new newsgroups follows",
        230 => "list of new articles by message-id follows",
        240 => "article received ok",
        340 => "Send article to be posted'",
        411 => 'no such news group',
        412 => "no newsgroup has been selected",
        420 => "no article(s) selected",
        423 => "no such article number in this group",
        430 => "no such article found",
        435 => 'article not wanted - do not send it',
        441 => "posting failed",
        422 => "no next/previous article in this newsgroup",
        500 => "command not supported",
        503 => "program error, function not performed"
    }

    def self.list
      STATUS
    end

    def self.msg(code)
      STATUS[code] || raise("unsupported code #{code}")
    end
  end
end