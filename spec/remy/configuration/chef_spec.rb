require 'spec_helper'

describe Remy::Configuration::Chef do
  subject { Remy::Configuration::Chef }
  before do
    Remy::Configuration::Chef.instance_variable_set(:@configuration, nil)
  end

  after do
    Remy::Configuration::Chef.instance_variable_set(:@configuration, nil)
  end

  def node_configuration(chef)
    chef.instance_variable_get(:@node_configuration)
  end

  describe '.configuration' do
    describe 'with no yml files' do
      it 'should return an empty mash' do
        Remy::Configuration::Chef.configuration.should == Hashie::Mash.new
      end
    end

    describe "yml files" do
      it 'should combine multiple yaml files into a mash' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = [chef_fixture('foo.yml'), chef_fixture('bar.yml')] }
        subject.configuration.yml_files.should == [chef_fixture('foo.yml'), chef_fixture('bar.yml')]
        subject.configuration.blah.should == 'bar' # From foo.yml
        subject.configuration.baz.should == 'baz' # From bar.yml
        subject.configuration.colors.to_hash.symbolize_keys.should == {:blue => 'blue', :green => 'green', :red => 'red'}
      end

      it 'should return an empty array if there are no yml files' do
        Remy::Configuration::Chef.configure {}
        subject.configuration.yml_files.should == []
      end

      it 'should not raise an error if there is a file does does not exist' do
        expect do
          Remy::Configuration::Chef.configure { |config| config.yml_files = ['does_not_exist.yml'] }
        end.should_not raise_error
      end
    end
    describe 'json config files' do
      before do
        pending
      end
      it 'should combine multiple json files into a mash' do
        Remy::Configuration::Chef.configure { |config| config.json_files = [chef_fixture('foo.json'), chef_fixture('bar.json')] }
        subject.configuration.json_files.should == [chef_fixture('foo.json'), chef_fixture('bar.json')]
        subject.configuration.blah.should == 'bar' # From foo.json
        subject.configuration.baz.should == 'baz' # From bar.json
        subject.configuration.colors.to_hash.symbolize_keys.should == {:blue => 'blue', :green => 'green', :red => 'red'}
      end

      it 'should return an empty array if there are no json files' do
        Remy::Configuration::Chef.configure {}
        subject.configuration.json_files.should == []
      end

      it 'should have the values in the json files override the values from the json files' do
      end
    end

    describe "cookbooks path" do
      it "should work if a single cookbook path is specified" do
        Remy::Configuration::Chef.configure { |config| config.cookbook_path = 'cookbooks' }
        subject.configuration.cookbook_path.should == ['cookbooks']
      end

      it "should work if multiple cookbook paths are specified" do
        Remy::Configuration::Chef.configure { |config| config.cookbook_path = ['cookbooks1', 'cookbooks2'] }
        subject.configuration.cookbook_path.should == ['cookbooks1', 'cookbooks2']
      end

      it "should return an empty array if no cookbook paths are specified" do
        Remy::Configuration::Chef.configure {}
        subject.configuration.cookbook_path.should == []
      end
    end

    describe "specs path" do
      it "should work if a single spec path is specified" do
        Remy::Configuration::Chef.configure { |config| config.spec_path = 'specs' }
        subject.configuration.spec_path.should == ['specs']
      end

      it "should work if multiple spec paths are specified" do
        Remy::Configuration::Chef.configure { |config| config.spec_path = ['specs1', 'specs2'] }
        subject.configuration.spec_path.should == ['specs1', 'specs2']
      end

      it "should return an empty array if no spec paths are specified" do
        Remy::Configuration::Chef.configure {}
        subject.configuration.spec_path.should == []
      end
    end

    describe "roles path" do
      it "should work if a single file is specified" do
        Remy::Configuration::Chef.configure { |config| config.roles_path = 'roles' }
        subject.configuration.roles_path.should == ['roles']
      end

      it "should work if multiple files are specified" do
        Remy::Configuration::Chef.configure { |config| config.roles_path = ['roles1', 'roles2'] }
        subject.configuration.roles_path.should == ['roles1', 'roles2']
      end

      it "should return an empty array if no roles paths are specified" do
        Remy::Configuration::Chef.configure {}
        subject.configuration.roles_path.should == []
      end
    end

    describe "node attributes" do
      it "should merge in the other node attributes from the hash" do
        Remy::Configuration::Chef.configure { |config| config.node_attributes = {:another_node_attribute => 'red'} }
        subject.configuration.another_node_attribute.should == 'red'
      end

      it "should not blow up if there no node attributes are specified" do
        lambda { Remy::Configuration::Chef.configure {} }.should_not raise_error
      end
    end

    describe "#remote_chef_dir" do
      it "should default to /var/chef if no option is given" do
        Remy::Configuration::Chef.configure {}
        subject.configuration.remote_chef_dir.should == '/var/chef'
      end

      it "should be able to be overriden" do
        Remy::Configuration::Chef.configure { |config| config.remote_chef_dir = '/foo/shef' }
        subject.configuration.remote_chef_dir.should == '/foo/shef'
      end
    end
  end

  context 'with a configuration' do
    before do
      Remy::Configuration::Chef.configure do |config|
        config.yml_files = [chef_fixture('chef.yml')]
      end
    end

    describe '.servers' do
      it 'returns all servers' do
        Remy::Configuration::Chef.servers.size.should == 3
        Remy::Configuration::Chef.servers['db.sharespost.com'].color.should == 'yellow'
      end
    end

    describe '.find_servers' do
      it 'should return servers that match the criteria' do
        Remy::Configuration::Chef.find_servers(:rails_env => 'demo').keys.should == ['web.sharespost.com', 'demo.sharespost.com']
      end

      it 'should return all servers if there are no criteria' do
        Remy::Configuration::Chef.find_servers.keys.should =~ ['db.sharespost.com', 'web.sharespost.com', 'demo.sharespost.com']
      end

      it 'should return servers that match the criteria (with multiple criteria)' do
        Remy::Configuration::Chef.find_servers(:rails_env => 'demo', :color => 'blue').keys.should == ['web.sharespost.com']
      end

      it "should return nil if there are no servers specified in the yaml file" do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.find_servers(:rails_env => 'demo').should be_nil
      end
    end

    describe '.find_server' do
      it 'should return the first server that matchs the criteria' do
        Remy::Configuration::Chef.find_server(:rails_env => 'demo').keys.should == ['web.sharespost.com']
      end

      it 'should return nil if there are no servers specifie in the yml files' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.find_server(:rails_env => 'demo').should be_nil
      end
    end

    describe '.find_server_config' do
      it 'should return the first server that matchs the criteria' do
        Remy::Configuration::Chef.find_server_config(:rails_env => 'demo').to_hash.should == {"color" => "blue", "recipes" => ["recipe[hello_world]"], "rails_env" => "demo", "ip_address" => IP_ADDRESS_OF_REMY_TEST}
      end

      it 'should return nil if no server info is found' do
        Remy::Configuration::Chef.find_server_config(:rails_env => 'foo').should be_nil
      end

      it 'should return nil if there are no servers in the yml files' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.find_server_config(:rails_env => 'foo').should be_nil
      end
    end

    describe '.find_server_config_by_name' do
      it 'should return the server that matches the name' do
        Remy::Configuration::Chef.find_server_config_by_name('db.sharespost.com').to_hash.should == {"encoding" => "utf8", "adapter" => "mysql2", "color" => "yellow", "rails_env" => "production", "ip_address" => "51.51.51.51"}
      end

      it 'should return nil if theres no server that matches the name' do
        Remy::Configuration::Chef.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end

      it 'should return nil (and not blow up) if there are no servers in the yml files' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end

      it 'should return nil (and not blow up) if there is no Remy configuration' do
        Remy.instance_variable_set('@configuration', nil)
        Remy::Configuration::Chef.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end
    end

    describe '.cloud_configuration' do
      it 'should return nil if it has not been specified in the yml files' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.cloud_configuration.should be_nil
      end

      it 'should return the cloud configuration options if present in the yml files' do
        Remy::Configuration::Chef.cloud_configuration.should == Hashie::Mash.new(
          :cloud_api_key => 'abcdefg12345',
          :cloud_provider => 'Rackspace',
          :cloud_username => 'sharespost',
          :flavor_id => 4,
          :image_id => 49,
          :server_name => 'new-server.somedomain.com')

      end

      it 'should return nil if there is currently no Remy configuration' do
        Remy::Configuration::Chef.instance_variable_set('@configuration', nil)
        Remy::Configuration::Chef.cloud_configuration.should be_nil
      end
    end

    describe '.bootstrap' do
      it 'should return nil if it has not been specified in the yml files' do
        Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        Remy::Configuration::Chef.bootstrap.should be_nil
      end

      it 'should return the bootstrap options if present in the yml files' do
        Remy::Configuration::Chef.bootstrap.should == Hashie::Mash.new(
          :ruby_version => '1.9.2',
          :gems => {
            :chef => '10.12.0',
            :rspec => '2.11.0',
            :bundler => '3.0.0'
          })
      end

      it 'should return nil if there is currently no Remy configuration' do
        Remy::Configuration::Chef.instance_variable_set('@configuration', nil)
        Remy::Configuration::Chef.bootstrap.should be_nil
      end
    end
  end

  describe "#initialize and the node configuration" do
    it 'should use the top-level IP address in the yml files, if one is present, and an ip address is not passed in as an argument' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
      chef = Remy::Chef.new
      node_configuration(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_configuration(chef).color.should == 'blue'
      node_configuration(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should allow the top-level values in the yml files (including the ip address) to be overridden' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
      chef = Remy::Chef.new(:ip_address => '1.2.3.4', :color => 'green')
      node_configuration(chef).ip_address.should == '1.2.3.4'
      node_configuration(chef).color.should == 'green'
      node_configuration(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should return properties from the :servers section of the yml file if the ip address is found in there' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:ip_address => '51.51.51.51')
      node_configuration(chef).ip_address.should == '51.51.51.51'
      node_configuration(chef).rails_env.should == 'production'
      node_configuration(chef).color.should == 'yellow'
      node_configuration(chef).adapter.should == 'mysql2'
      node_configuration(chef).encoding.should == 'utf8'
    end

    it 'should allow properties from the servers section of the yml file to be overridden plus additional options added' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:ip_address => '51.51.51.51', :color => 'purple', :temperature => 'warm')
      node_configuration(chef).color.should == 'purple' # Overrides 'yellow' from the yml files
      node_configuration(chef).temperature.should == 'warm' # A new node attribute which is not present in the yml files
    end

    it 'should allow the chef args to be specified (and not merge this chef_args value into the node configuration)' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:chef_args => '-l debug')
      node_configuration(chef).chef_args.should be_nil
      chef.instance_variable_get(:@chef_args).should == '-l debug'
    end

    it 'should allow the quiet option to be specified (and not merge this option into the node configuration)' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:quiet => true)
      node_configuration(chef).quiet.should be_nil
      chef.instance_variable_get(:@quiet).should be_true
    end

    it 'should not modify the global Remy configuration, but rather only the node configuration for this particular Chef node' do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('bar.yml') }
      Remy::Configuration::Chef.configuration.another_node_attribute.should == 'hot'
      chef = Remy::Chef.new(:another_node_attribute => 'cold')
      node_configuration(chef).another_node_attribute.should == 'cold'
      Remy::Configuration::Chef.configuration.another_node_attribute.should == 'hot' # Unchanged from its original value                                                                                                  # do some checks
    end
  end

  describe '#run' do
    before do
      Remy::Configuration::Chef.configure { |config| config.yml_files = chef_fixture('chef.yml') }
    end

    it 'should work with a hash as its argument' do
      chef = Remy::Chef.new(:ip_address => IP_ADDRESS_OF_REMY_TEST)
      node_configuration(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_configuration(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should work with JSON as its argument' do
      chef = Remy::Chef.new("{\"ip_address\":\"#{IP_ADDRESS_OF_REMY_TEST}\"}")
      node_configuration(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_configuration(chef).recipes.should == ['recipe[hello_world]']
    end
  end
end
