require 'spec_helper'

describe Remy::Config::Chef do
  subject { Remy::Config::Chef }
  before do
    subject.instance_variable_set(:@config, nil)
  end

  after do
    subject.instance_variable_set(:@config, nil)
  end

  def node_config(chef)
    chef.instance_variable_get(:@node_config)
  end

  describe '.save_node_json' do
    let(:node_json_output_path) { Dir.tmpdir + '/foo/chef/node.json' }

    after do
      FileUtils.rm node_json_output_path, :force => true
    end

    it 'should save the node json file to the specified directory' do
      File.exist?(node_json_output_path).should be_false
      subject.save_node_json(node_json_output_path)
      File.exist?(node_json_output_path).should be_true
    end

    it 'should include chef configuration yml data as json' do
      subject.configure { |config| config.yml_files = chef_fixture('foo.yml') }
      subject.save_node_json(node_json_output_path)
      data_from_json = JSON.parse(File.read(node_json_output_path))
      data_from_json['blah'].should == 'bar'
    end
  end

  describe '.config' do
    describe 'with no yml files' do
      it 'should return an empty mash' do
        subject.config.should == Hashie::Mash.new
      end
    end

    describe "yml files" do
      it 'should combine multiple yaml files into a mash' do
        subject.configure { |config| config.yml_files = [chef_fixture('foo.yml'), chef_fixture('bar.yml')] }
        subject.config.yml_files.should == [chef_fixture('foo.yml'), chef_fixture('bar.yml')]
        subject.config.blah.should == 'bar' # From foo.yml
        subject.config.baz.should == 'baz' # From bar.yml
        subject.config.colors.to_hash.symbolize_keys.should == {:blue => 'blue', :green => 'green', :red => 'red'}
      end

      it 'should return an empty array if there are no yml files' do
        subject.configure {}
        subject.config.yml_files.should == []
      end

      it 'should not raise an error if there is a file does does not exist' do
        expect do
          subject.configure { |config| config.yml_files = ['does_not_exist.yml'] }
        end.should_not raise_error
      end
    end
    describe 'json config files' do
      before do
        pending
      end
      it 'should combine multiple json files into a mash' do
        subject.configure { |config| config.json_files = [chef_fixture('foo.json'), chef_fixture('bar.json')] }
        subject.config.json_files.should == [chef_fixture('foo.json'), chef_fixture('bar.json')]
        subject.config.blah.should == 'bar' # From foo.json
        subject.config.baz.should == 'baz' # From bar.json
        subject.config.colors.to_hash.symbolize_keys.should == {:blue => 'blue', :green => 'green', :red => 'red'}
      end

      it 'should return an empty array if there are no json files' do
        subject.configure {}
        subject.config.json_files.should == []
      end

      it 'should have the values in the json files override the values from the json files' do
      end
    end

    describe "cookbooks path" do
      it "should work if a single cookbook path is specified" do
        subject.configure { |config| config.cookbook_path = 'cookbooks' }
        subject.config.cookbook_path.should == ['cookbooks']
      end

      it "should work if multiple cookbook paths are specified" do
        subject.configure { |config| config.cookbook_path = ['cookbooks1', 'cookbooks2'] }
        subject.config.cookbook_path.should == ['cookbooks1', 'cookbooks2']
      end

      it "should return an empty array if no cookbook paths are specified" do
        subject.configure {}
        subject.config.cookbook_path.should == []
      end
    end

    describe "specs path" do
      it "should work if a single spec path is specified" do
        subject.configure { |config| config.spec_path = 'specs' }
        subject.config.spec_path.should == ['specs']
      end

      it "should work if multiple spec paths are specified" do
        subject.configure { |config| config.spec_path = ['specs1', 'specs2'] }
        subject.config.spec_path.should == ['specs1', 'specs2']
      end

      it "should return an empty array if no spec paths are specified" do
        subject.configure {}
        subject.config.spec_path.should == []
      end
    end

    describe "roles path" do
      it "should work if a single file is specified" do
        subject.configure { |config| config.roles_path = 'roles' }
        subject.config.roles_path.should == ['roles']
      end

      it "should work if multiple files are specified" do
        subject.configure { |config| config.roles_path = ['roles1', 'roles2'] }
        subject.config.roles_path.should == ['roles1', 'roles2']
      end

      it "should return an empty array if no roles paths are specified" do
        subject.configure {}
        subject.config.roles_path.should == []
      end
    end

    describe "node attributes" do
      it "should merge in the other node attributes from the hash" do
        subject.configure { |config| config.node_attributes = {:another_node_attribute => 'red'} }
        subject.config.another_node_attribute.should == 'red'
      end

      it "should not blow up if there no node attributes are specified" do
        lambda { subject.configure {} }.should_not raise_error
      end
    end

    describe "#remote_chef_dir" do
      it "should default to /var/chef if no option is given" do
        subject.configure {}
        subject.config.remote_chef_dir.should == '/var/chef'
      end

      it "should be able to be overriden" do
        subject.configure { |config| config.remote_chef_dir = '/foo/shef' }
        subject.config.remote_chef_dir.should == '/foo/shef'
      end
    end
  end

  context 'with a config' do
    before do
      subject.configure do |config|
        config.yml_files = [chef_fixture('chef.yml')]
      end
    end

    describe '.servers' do
      it 'returns all servers' do
        subject.servers.size.should == 3
        subject.servers['db.sharespost.com'].color.should == 'yellow'
      end
    end

    describe '.find_servers' do
      it 'should return servers that match the criteria' do
        subject.find_servers(:rails_env => 'demo').keys.should == ['web.sharespost.com', 'demo.sharespost.com']
      end

      it 'should return all servers if there are no criteria' do
        subject.find_servers.keys.should =~ ['db.sharespost.com', 'web.sharespost.com', 'demo.sharespost.com']
      end

      it 'should return servers that match the criteria (with multiple criteria)' do
        subject.find_servers(:rails_env => 'demo', :color => 'blue').keys.should == ['web.sharespost.com']
      end

      it "should return nil if there are no servers specified in the yaml file" do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.find_servers(:rails_env => 'demo').should be_nil
      end
    end

    describe '.find_server' do
      it 'should return the first server that matchs the criteria' do
        subject.find_server(:rails_env => 'demo').keys.should == ['web.sharespost.com']
      end

      it 'should return nil if there are no servers specifie in the yml files' do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.find_server(:rails_env => 'demo').should be_nil
      end
    end

    describe '.find_server_config' do
      it 'should return the first server that matchs the criteria' do
        subject.find_server_config(:rails_env => 'demo').to_hash.should == {"color" => "blue", "recipes" => ["recipe[hello_world]"], "rails_env" => "demo", "ip_address" => IP_ADDRESS_OF_REMY_TEST}
      end

      it 'should return nil if no server info is found' do
        subject.find_server_config(:rails_env => 'foo').should be_nil
      end

      it 'should return nil if there are no servers in the yml files' do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.find_server_config(:rails_env => 'foo').should be_nil
      end
    end

    describe '.find_server_config_by_name' do
      it 'should return the server that matches the name' do
        subject.find_server_config_by_name('db.sharespost.com').to_hash.should == {"encoding" => "utf8", "adapter" => "mysql2", "color" => "yellow", "rails_env" => "production", "ip_address" => "51.51.51.51"}
      end

      it 'should return nil if theres no server that matches the name' do
        subject.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end

      it 'should return nil (and not blow up) if there are no servers in the yml files' do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end

      it 'should return nil (and not blow up) if there is no Remy config' do
        Remy.instance_variable_set('@config', nil)
        subject.find_server_config_by_name('db.asdfjkll.com').should be_nil
      end
    end

    describe '.cloud_config' do
      it 'should return nil if it has not been specified in the yml files' do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.cloud_config.should be_nil
      end

      it 'should return the cloud config options if present in the yml files' do
        subject.cloud_config.should == Hashie::Mash.new(
          :cloud_api_key => 'abcdefg12345',
          :cloud_provider => 'Rackspace',
          :cloud_username => 'sharespost',
          :flavor_id => 4,
          :image_id => 49,
          :server_name => 'new-server.somedomain.com')

      end

      it 'should return nil if there is currently no Remy config' do
        subject.instance_variable_set('@config', nil)
        subject.cloud_config.should be_nil
      end
    end

    describe '.bootstrap' do
      it 'should return nil if it has not been specified in the yml files' do
        subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
        subject.bootstrap.should be_nil
      end

      it 'should return the bootstrap options if present in the yml files' do
        subject.bootstrap.should == Hashie::Mash.new(
          :ruby_version => '1.9.2',
          :gems => {
            :chef => '10.12.0',
            :rspec => '2.11.0',
            :bundler => '3.0.0'
          })
      end

      it 'should return nil if there is currently no Remy config' do
        subject.instance_variable_set('@config', nil)
        subject.bootstrap.should be_nil
      end
    end
  end

  describe "#initialize and the node config" do
    it 'should use the top-level IP address in the yml files, if one is present, and an ip address is not passed in as an argument' do
      subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
      chef = Remy::Chef.new
      node_config(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_config(chef).color.should == 'blue'
      node_config(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should allow the top-level values in the yml files (including the ip address) to be overridden' do
      subject.configure { |config| config.yml_files = chef_fixture('hello_world_chef.yml') }
      chef = Remy::Chef.new(:ip_address => '1.2.3.4', :color => 'green')
      node_config(chef).ip_address.should == '1.2.3.4'
      node_config(chef).color.should == 'green'
      node_config(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should return properties from the :servers section of the yml file if the ip address is found in there' do
      subject.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:ip_address => '51.51.51.51')
      node_config(chef).ip_address.should == '51.51.51.51'
      node_config(chef).rails_env.should == 'production'
      node_config(chef).color.should == 'yellow'
      node_config(chef).adapter.should == 'mysql2'
      node_config(chef).encoding.should == 'utf8'
    end

    it 'should allow properties from the servers section of the yml file to be overridden plus additional options added' do
      subject.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:ip_address => '51.51.51.51', :color => 'purple', :temperature => 'warm')
      node_config(chef).color.should == 'purple' # Overrides 'yellow' from the yml files
      node_config(chef).temperature.should == 'warm' # A new node attribute which is not present in the yml files
    end

    it 'should allow the chef args to be specified (and not merge this chef_args value into the node config)' do
      subject.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:chef_args => '-l debug')
      node_config(chef).chef_args.should be_nil
      chef.instance_variable_get(:@chef_args).should == '-l debug'
    end

    it 'should allow the quiet option to be specified (and not merge this option into the node config)' do
      subject.configure { |config| config.yml_files = chef_fixture('chef.yml') }
      chef = Remy::Chef.new(:quiet => true)
      node_config(chef).quiet.should be_nil
      chef.instance_variable_get(:@quiet).should be_true
    end

    it 'should not modify the global Remy config, but rather only the node config for this particular Chef node' do
      subject.configure { |config| config.yml_files = chef_fixture('bar.yml') }
      subject.config.another_node_attribute.should == 'hot'
      chef = Remy::Chef.new(:another_node_attribute => 'cold')
      node_config(chef).another_node_attribute.should == 'cold'
      subject.config.another_node_attribute.should == 'hot' # Unchanged from its original value                                                                                                  # do some checks
    end
  end

  describe '#run' do
    before do
      subject.configure { |config| config.yml_files = chef_fixture('chef.yml') }
    end

    it 'should work with a hash as its argument' do
      chef = Remy::Chef.new(:ip_address => IP_ADDRESS_OF_REMY_TEST)
      node_config(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_config(chef).recipes.should == ['recipe[hello_world]']
    end

    it 'should work with JSON as its argument' do
      chef = Remy::Chef.new("{\"ip_address\":\"#{IP_ADDRESS_OF_REMY_TEST}\"}")
      node_config(chef).ip_address.should == IP_ADDRESS_OF_REMY_TEST
      node_config(chef).recipes.should == ['recipe[hello_world]']
    end
  end
end
