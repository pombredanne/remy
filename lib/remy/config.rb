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
  module Config
    def config
      @config ? @config : Hashie::Mash.new
    end

    def to_json
      config.to_json
    end

    def servers
      config.servers
    end

    def find_servers(options = {})
      return nil unless config.servers
      Hashie::Mash.new(config.servers.inject({}) do |hash, (server_name, server_config)|
        found = options.all? { |(key, value)| server_config[key] == value }
        hash[server_name] = server_config if found
        hash
      end)
    end

    def find_server(options = {})
      return nil unless config.servers
      server_name, server_config = config.servers.detect do |(server_name, server_config)|
        options.all? { |(key, value)| server_config[key] == value }
      end
      {server_name => server_config.nil? ? nil : server_config.dup}
    end

    def find_server_config(options = {})
      find_server(options).try(:values).try(:first)
    end

    def find_server_config_by_name(name)
      return nil unless config.servers
      config.servers.find { |(server_name, _)| server_name == name }.try(:last)
    end

    def cloud_config
      config && config.cloud_config
    end

    def bootstrap
      config && config.bootstrap
    end

    def determine_ip_addresses_for_remy_run(rake_args)
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
        ip_addresses << config.ip_address
      end
      ip_addresses.compact
    end

    # Converts "foo:bar baz:blech" to {:foo => 'bar', :baz => 'blech'}
    def convert_properties_to_hash(properties)
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
