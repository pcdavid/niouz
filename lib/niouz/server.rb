# -*- ruby -*-

module Niouz
  # The main entry point of the server. Creates a new NNTPSession for
  # each client.
  class NNTPServer < GServer
    DEFAULT_PORT = 119

    # The grousp/articles store to serve.
    attr_accessor :store

    def initialize(port = DEFAULT_PORT, host = GServer::DEFAULT_HOST,logger = Logger.new($stderr))
      @logger=logger
      @logger.info("[SERVER] starting")
      super(port, host, Float::MAX, nil, true)
    end

    def serve(sock)
      NNTPConnection.new(sock, @store, @logger).serve
    end

    def connecting(client)
      addr = client.peeraddr
      @logger.debug("[CLIENT] connect(#{connections}) server:#{@host}:#{@port} client:#{addr[1]} #{addr[2]}<#{addr[3]}>")
      true
    end

    def disconnecting(clientPort)
      @logger.debug("[CLIENT] disconnect #{@host}:#{@port}  client:#{clientPort}")
    end

    # An individual NNTP session with a client.
    class NNTPConnection
      def initialize(socket, storage, logger)

        @socket, @storage = socket, storage
        @logger=logger

        @session=Niouz::Session.new(@storage)
        @protocol=Niouz::Protocol.new(@session, @socket)
      end


      def serve
        while (request = getline)
          begin
            @logger.debug("RECEIVED: '#{request.inspect}'")
            if @protocol.dispatch(request.strip) == :quit
              close
              return
            end
          rescue Interrupt
            raise
          rescue Exception => err
            @socket.write("500 internal error (exception)\r\n")
            @logger.error("Exception: #{err.message}\n#{err.backtrace.join("\n")}")
          end
        end
      end

      private
      def close
        @socket.close
      end

      # Reads a single line from the client and returns it.
      def getline
        return @socket.gets
      end


    end
  end
end