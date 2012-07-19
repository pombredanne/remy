require 'spec_helper'
describe Remy::Config::Node do
  subject { Remy::Config::Node }
  before do
    subject.instance_variable_set(:@config, nil)
  end

  after do
    subject.instance_variable_set(:@config, nil)
  end

  describe '.config' do
    describe "from json file" do
      it 'should extract the contents of the json file' do
        subject.configure { |config| config.json_file = chef_fixture('node.json') }
        subject.config.blah.should == 'bar'
      end
    end
  end
end
