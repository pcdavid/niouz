require 'spec_helper'

describe Niouz::Rfc822Parser do
  let(:input) {
    "header: value\nCamel-Header: value-camel"
  }

  it "should parse to symbolic hash" do
    hdr=Niouz::Rfc822Parser.parse_header_to_sym(input)
    hdr[:header] == 'value'
    hdr[:camel_header] == 'value-camel'
  end
end