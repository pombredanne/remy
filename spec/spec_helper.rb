ENV["RAILS_ENV"] ||= 'test'

require 'rubygems'
require 'bundler/setup'
require 'active_support'
require 'mocha'
require 'json'
require 'remy'

Dir[File.join(File.dirname(__FILE__), 'spec', 'support', '**' '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :mocha
end

IP_ADDRESS_OF_REMY_TEST = '108.166.98.115'

def chef_fixture(file)
  File.join(File.dirname(__FILE__), 'fixtures/' + file)
end

def project_root
  File.expand_path(File.join(File.dirname(__FILE__), '../'))
end
