require 'spec_helper'

describe Niouz::Storage::Filesystem::UserFile do
  let(:uf){Niouz::Storage::Filesystem::UserFile}
  let(:input) { StringIO.new(
      "Username: user1\nPassword: passwd1\nEmail: email1\nName: name1\n\n" +
          "Username: user2\nPassword: passwd2\nEmail: email2\nName: name2\n"
  )
  }
  it "should load a file" do
    users=uf.read(input)
    users['user1'].should_not be_nil
    users['user2'].should_not be_nil
  end
  it "should parse the users correctly" do
    users=uf.read(input)
    user=users['user1']
    user.username.should == 'user1'
    user.password.should == 'passwd1'
    user.name.should == 'name1'
    user.email.should == 'email1'
  end
end