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
    class Chef
      extend Remy::Configuration
      include ::Remy::Shell
      include FileUtils

      def self.configure
        temp_config = Hashie::Mash.new(:node_attributes => {}, :yml_files => [], :remote_chef_dir => '/var/chef')
        yield temp_config
        yml_files = [temp_config.yml_files].compact.flatten
        @configuration = Hashie::Mash.new({:yml_files => yml_files,
                                           :remote_chef_dir => temp_config.remote_chef_dir,
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
    end
  end
end
