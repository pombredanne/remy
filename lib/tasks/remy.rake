require 'remy'

namespace :remy do
  desc 'Create a JSON file from the contents of the Chef yml config files for use on development boxes by the Rails application.'
  task :save_node_json, :rake_args do |task, options|
    Remy::Config::Chef.save_node_json(options[:rake_args])
  end

  desc 'ssh to a named box'
  task :ssh, :rake_args do |task, options|
    user = Remy::Config::Chef.config.user || 'root'
    if ip_address = Remy::Config::Chef.determine_ip_addresses_for_remy_run(options[:rake_args]).try(:first)
      exec "ssh #{user}@#{ip_address}"
    end
  end

  namespace :chef do
    desc 'run chef solo'
    task :run, :rake_args do |task, options|
      Remy::Chef.rake_run(options[:rake_args])
    end
  end

  namespace :server do
    desc 'create a server'
    task :create, :server_name, :flavor_id, :cloud_api_key, :cloud_username, :cloud_provider, :image_id do |task, options|
      Remy::Server.new(options).create
    end

    desc 'bootstrap chef'
    task :bootstrap, :ip_address, :password do |task, options|
      Remy::Bootstrap.new(options).run
    end

    desc 'create a server and bootstrap chef'
    task :create_and_bootstrap, :server_name, :flavor_id, :cloud_api_key, :cloud_username, :cloud_provider, :image_id do |task, options|
      result = Remy::Server.new({:raise_exception => true}.merge(options)).create
      Rake::Task[:'remy:server:bootstrap'].invoke(result[:ip_address], result[:password])
    end
  end
end
