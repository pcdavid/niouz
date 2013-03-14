require 'spec_helper'

describe Niouz::Protocol do
  let(:session) { mock(:greet => [200]) }
  it "should parse HELP and dispatch" do
    spec_command(:help)
  end

  it "should parse LIST and dispatch" do
    spec_command(:list)
  end

  it "should detect capabilities without arg" do
    spec_command(:capabilities)
  end
  it "should detect capabilities with arg" do

    session.should_receive(:capabilities).with("AUTOUPDATE").and_return([200])
    p=Niouz::Protocol.new(session)
    p.dispatch("CAPABILITIES AUTOUPDATE")
  end

  def spec_command(cmd)
    cmd_s=cmd.to_s.upcase
    session.should_receive(cmd).and_return([200])
    p=Niouz::Protocol.new(session)
    p.dispatch(cmd_s)
  end
end