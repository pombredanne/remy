#--
# Copyright (c) 2011 Gregory S. Woodward
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Remy
  module Configuration
    class TempConfig
      attr_accessor :yml_files, :cookbook_path, :spec_path, :remote_chef_dir, :node_attributes, :roles_path

      def initialize
        @yml_files = []
        @node_attributes = {}
      end
    end

    class Chef
      include ::Remy::Shell
      include FileUtils

      def self.configure
        temp_config = TempConfig.new
        yield temp_config
        yml_files = [temp_config.yml_files].compact.flatten
        @configuration = Hashie::Mash.new({:yml_files => yml_files,
                                           :remote_chef_dir => (temp_config.remote_chef_dir || '/var/chef'),
                                           :roles_path => [temp_config.roles_path].compact.flatten,
                                           :spec_path => [temp_config.spec_path].compact.flatten,
                                           :cookbook_path => [temp_config.cookbook_path].compact.flatten}.merge!(temp_config.node_attributes))

        yml_files.each do |filename|
          begin
            @configuration.deep_merge!(YAML.load(ERB.new(File.read(filename)).result) || {})
          rescue SystemCallError, IOError
            # do nothing if the chef.yml file could not be read (it's not needed for every usage of remy, just certain ones)
          end
        end
      end

      def self.configuration
        @configuration ? @configuration : Hashie::Mash.new
      end

      def self.to_json
        configuration.to_json
      end

      def self.servers
        configuration.servers
      end

      def self.find_servers(options = {})
        return nil unless configuration.servers
        Hashie::Mash.new(configuration.servers.inject({}) do |hash, (server_name, server_config)|
          found = options.all? { |(key, value)| server_config[key] == value }
          hash[server_name] = server_config if found
          hash
        end)
      end

      def self.find_server(options = {})
        return nil unless configuration.servers
        server_name, server_config = configuration.servers.detect do |(server_name, server_config)|
          options.all? { |(key, value)| server_config[key] == value }
        end
        {server_name => server_config.nil? ? nil : server_config.dup}
      end

      def self.find_server_config(options = {})
        find_server(options).try(:values).try(:first)
      end

      def self.find_server_config_by_name(name)
        return nil unless configuration.servers
        configuration.servers.find { |(server_name, _)| server_name == name }.try(:last)
      end

      def self.cloud_configuration
        configuration && configuration.cloud_configuration
      end

      def self.bootstrap
        configuration && configuration.bootstrap
      end

      def self.determine_ip_addresses_for_remy_run(rake_args)
        ip_addresses = []
        if options_hash = convert_properties_to_hash(rake_args)
          servers = find_servers(options_hash)
          if !servers.empty?
            ip_addresses = servers.collect { |server_name, chef_option| chef_option.ip_address }
          else
            ip_addresses = [options_hash[:ip_address]]
          end
        else
          names_or_ip_addresses = rake_args.present? ? rake_args.split(' ').collect { |name| name.strip } : []
          names_or_ip_addresses.each do |name_or_ip_address|
            # From: http://www.regular-expressions.info/examples.html
            ip_address_regex = '\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
            if name_or_ip_address.match(ip_address_regex)
              ip_addresses << name_or_ip_address
            elsif server_config = find_server_config_by_name(name_or_ip_address)
              ip_addresses << server_config.ip_address
            end
          end
          ip_addresses << configuration.ip_address
        end
        ip_addresses.compact
      end

      # Converts "foo:bar baz:blech" to {:foo => 'bar', :baz => 'blech'}
      def self.convert_properties_to_hash(properties)
        if properties =~ /:/
          properties.split(' ').inject({}) do |result, pair|
            key, value = pair.split(':')
            result[key] = value
            result
          end.symbolize_keys
        else
          nil
        end
      end
    end
  end
end
