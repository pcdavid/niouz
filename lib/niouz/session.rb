module Niouz
  class Session

    def initialize(storage)
      @storage=storage
      @group=nil
      @article=nil
    end
    include CoreCommands
    include AuthCommands

    def unknown
      r(500)
    end

    private


    # Sends a multi-line response (for example an article body)
    # to the client.
    def encodelong(content)
      content.lines.map do |line|
        dot_escape(line)
      end.join
    end

    def dot_escape(str)
      str.sub(/^\./, '..')
    end

    def r(code, body=nil, code_msg=nil)
      body=body.join("\n") if body.kind_of?(Array)
      [code, body, code_msg || Niouz::Status.msg(code)]
    end
  end
end