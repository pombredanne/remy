require 'spec_helper'

describe Remy do

  describe '.to_json' do
    it 'should create the expected JSON' do
      Remy::Configuration::Chef.configure {}
      lambda do
        JSON.parse(subject.to_json)
      end.should_not raise_error
    end
  end


  describe 'support for the rake tasks' do
    before do
      Remy::Configuration::Chef.configure do |config|
        config.yml_files = ['fixtures/foo.yml', 'fixtures/bar.yml', 'fixtures/chef.yml'].map { |f| File.join(File.dirname(__FILE__), f) }
      end
    end

    describe '.convert_properties_to_hash' do
      it 'should convert properties to a hash' do
        Remy::Configuration::Chef.send(:convert_properties_to_hash, ' foo:bar blah:blech').should == {:foo => 'bar', :blah => 'blech'}
      end

      it 'should convert a blank string to nil' do
        Remy::Configuration::Chef.send(:convert_properties_to_hash, '  ').should be_nil
      end

      it 'should return nil if the string is not in property format' do
        Remy::Configuration::Chef.send(:convert_properties_to_hash, 'demo.sharespost.com').should be_nil
      end
    end

    describe '.determine_ip_addresses_for_remy_run' do
      context 'top level ip address is present in the yml files' do
        before do
          Remy::Configuration::Chef.configure { |config| config.yml_files = File.join(File.dirname(__FILE__), 'fixtures/hello_world_chef.yml') }
        end

        it 'should return the ip address in the yml file if no ip address is given and an ip is present in the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, '').should == [IP_ADDRESS_OF_REMY_TEST]
        end

        it 'should handle receiving no parameters' do
          expect do
            Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, nil).should == [IP_ADDRESS_OF_REMY_TEST]
          end.to_not raise_error
        end
      end

      context 'no top level ip address is present in the yml files' do
        before do
          Remy::Configuration::Chef.configure { |config| config.yml_files = File.join(File.dirname(__FILE__), 'fixtures/foo.yml') }
        end

        it 'should return nothing if no ip address is given and no top-level ip address is in the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, '').should == []
        end

        it 'should return the ip address if an ip address is given and no top-level ip address is in the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, '1.2.3.4').should == ['1.2.3.4']
        end

        it 'should handle receiving no parameters' do
          expect do
            Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, nil).should == []
          end.to_not raise_error
        end
      end

      context ':servers section present in the yml files' do
        before do
          Remy::Configuration::Chef.configure { |config| config.yml_files = File.join(File.dirname(__FILE__), 'fixtures/chef.yml') }
        end

        it 'should return an ip address if an ip address is given as property value (this IP address is not in the :servers section of the yml files)' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'ip_address:1.2.3.4').should == ['1.2.3.4']
        end

        it 'should return the ip address if the ip address was found in the :servers section of the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'ip_address:52.52.52.52').should == ['52.52.52.52']
        end

        it 'should return the IP address - the IP address is specified, but is not found in the servers section in the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, '1.2.3.4').should == ['1.2.3.4']
        end

        it 'should return the IP address - the IP address is specified, and is found in the servers section in the yml files' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, '52.52.52.52').should == ['52.52.52.52']
        end

        it 'should be able to find servers by name from the :servers section of the yml file' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'demo.sharespost.com').should == ['52.52.52.52']
        end

        it 'should be able to find servers by multiple names' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, ' demo.sharespost.com  db.sharespost.com ').should == ['52.52.52.52', '51.51.51.51']
        end

        it 'should be able to find servers by multiple names and ip addresses' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, ' demo.sharespost.com   51.51.51.51').should == ['52.52.52.52', '51.51.51.51']
        end

        it 'should be able to find all of the servers from the yml files that match certain attributes' do
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'rails_env:demo').should == [IP_ADDRESS_OF_REMY_TEST, '52.52.52.52']
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'rails_env:demo color:green').should == ['52.52.52.52']
          Remy::Configuration::Chef.send(:determine_ip_addresses_for_remy_run, 'rails_env:demo color:yellow').should == []
        end
      end
    end
  end
end

