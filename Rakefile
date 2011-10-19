require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'remy/emile'

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
end

task :default => :spec


namespace :remy do
  namespace :chef do
    desc 'bootstrap chef'
    task :bootstrap, :ip_address, :password do |task, options|
      Remy::Emile.new(options).bootstrap
    end
  end
end
