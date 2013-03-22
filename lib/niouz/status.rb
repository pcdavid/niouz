module Niouz
  module Status
    STATUS = {
        100 => "help text follows",
        101 => "capabilities list", #multiline
        111 => "----date",
        200 => 'service available, posting allowed',
        201 => 'service available, posting prohibited',
        202 => 'slave status acknowledged',
        205 => "closing connection - goodbye!",
        211 => "----group answer", #listgroup multiline
        215 => "order of fields in overview database",
        220 => "article retrieved", #multiline
        221 => "article retrieved (head)", #multiline
        222 => "article retrieved (body)", #multiline
        223 => "article retrieved: request text separately",
        224 => "Overview information follows", #multiline
        225 => "hdr???", # multiline
        230 => "list of new articles by message-id follows", #multiline
        231 => "list of new newsgroups follows", #multiline
        240 => "article received ok",
        281 => "authentication accepted", #http://tools.ietf.org/html/rfc4643#section-2.3
        340 => "send article to be posted'",
        381 => "password required", #http://tools.ietf.org/html/rfc4643#section-2.3
        400 => "server is closing connection", #RFC 3977 3.2.1
        401 => "client must change the state of the connection in some other manner", #RFC 3977 3.2.1, 5.2
        402 => "service temporarily unavailable",
        403 => "temporary error",
        411 => 'no such news group',
        412 => "no newsgroup has been selected",
        420 => "no article(s) selected",
        423 => "no such article number in this group",
        430 => "no such article found",
        435 => 'article not wanted - do not send it',
        422 => "no next/previous article in this newsgroup",
        440 => "posting not permitted",
        441 => "posting failed",
        480 => "client must authenticate itself to the server", #RFC 3977 3.2.1
        481 => "authentication failed/rejected", #http://tools.ietf.org/html/rfc4643#section-2.3
        482 => "authentication commands issued out of sequence", #http://tools.ietf.org/html/rfc4643#section-2.3
        483 => "client must negotiate appropriate privacy protection", #RFC 3977 3.2.1
        500 => "unknown command", #RFC 3977 3.2.1.1
        501 => "unknown option/syntax error/too many arguments",
        502 => "terminate and restart", #RFC 3977 3.2.1
        503 => "program error, function not performed",
        504 => "base64 encoding error"
    }

    def self.list
      STATUS
    end

    def self.msg(code)
      STATUS[code] || raise("unsupported code #{code}")
    end
  end
end