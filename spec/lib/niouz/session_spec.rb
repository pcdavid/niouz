require 'spec_helper'

describe Niouz::Session do
  let(:storage) {mock}
  let(:session){Niouz::Session.new(storage)}
  it "should return capabilities" do
    resp=session.capabilities
    resp[0].should == 101
    resp[1].should == "VERSION 2\nREADER\nNEWNEWS\nPOST\nLIST\nAUTHINFO USER"
  end
end