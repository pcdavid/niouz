require 'spec_helper'

describe Niouz::Rfc822Parser do
  let(:input) {
    "header: value\nCamel-Header: value-camel"
  }

  let(:body) {
    "alles ok"
  }
  let(:head1) {
    txt =<<EOF
From: none <""popel\"@(none)">
MIME-Version: 1.0
Newsgroups: projects.foobar,test
Subject: jhuhu
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding: 7bit
EOF

  }

  let(:head2) {
    txt=<<EOF
Message-ID: <a58b74393c097dbadb7c7a866f9ed5af@beast>
Date: Sat, 16 Mar 2013 22:35:33 +0100
EOF
  }


  let(:news_ok) {
    Niouz::Rfc822Parser.new(head1+head2+"\n"+body)
  }

  it "should parse to symbolic hash" do
    hdr=Niouz::Rfc822Parser.parse_header_to_sym(input)
    hdr[:header] == 'value'
    hdr[:camel_header] == 'value-camel'
  end

  describe "as a class" do
    it "should extract the headers" do
      news_ok.headers['Message-ID'].should == "<a58b74393c097dbadb7c7a866f9ed5af@beast>"
    end
    it "should extract the newsgroup names" do
      news_ok.newsgroup_names.should == ['projects.foobar', 'test']
    end
    it "should extract date" do
      news_ok.date.should == Time.parse("2013-03-16 22:35:33 +0100")
    end
    it "should have a head" do
      news_ok.head.should == head1 + head2
    end
    it "should have a body" do
      news_ok.body.should == body
    end

    describe "when needs fixing" do
      let(:news_fixed) {
        Niouz::Rfc822Parser.new(head1+"\n"+body, true)
      }

      it "should fix the message id" do
        news_fixed.message_id.should_not be_nil
        news_fixed.content.should =~ /<#{news_fixed.message_id}>/
      end
    end

  end
end