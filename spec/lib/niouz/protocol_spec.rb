require 'spec_helper'

describe Niouz::Protocol do
  let(:session) { mock }
  it "should parse HELP and dispatch" do
    spec_command(:help)
  end

  it "should parse LIST and dispatch" do
    spec_command(:list)
  end

  it "should parse GROUP"

  end
  def spec_command(cmd)
    cmd_s=cmd.to_s.upcase
    session.should_receive(cmd)
    p=Niouz::Protocol.new(session)
    p.dispatch(cmd_s)
  end
end