require 'spec_helper'
describe Remy::Configuration::Node do
  subject { Remy::Configuration::Node }
  before do
    subject.instance_variable_set(:@configuration, nil)
  end

  after do
    subject.instance_variable_set(:@configuration, nil)
  end

  describe '.configuration' do
    describe "from json file" do
      it 'should extract the contents of the json file' do
        subject.configure { |config| config.json_file = chef_fixture('node.json') }
        subject.configuration.blah.should == 'bar'
      end
    end
  end
end
