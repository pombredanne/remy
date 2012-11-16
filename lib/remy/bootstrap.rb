module Remy
  class Bootstrap
    include ::Remy::Shell

    attr_reader :ip_address, :ruby_version, :password, :gems, :public_ssh_key

    def initialize(options = { })
      @ip_address = options[:ip_address]
      @password = options[:password]
      options = (Remy::Config::Chef.bootstrap || {}).merge(options).symbolize_keys
      @ruby_version = options[:ruby_version] || '1.8.7'
      @gems = options[:gems] || {}
      @public_ssh_key = options[:public_ssh_key]
      @quiet = options[:quiet] || false
    end

    def run
      copy_ssh_key_to_remote
      add_ssh_key_locally_if_necessary
      update_linux_distribution
      install_rvm
      install_gems_to_bootstrap_chef
    end

    private

    def apt_get_rvm_packages
      # This list of required packages came from doing "rvm requirements"
      remote_apt_get 'build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion'
    end

    def add_ssh_key_locally_if_necessary
      private_ssh_key = public_ssh_key.chomp(File.extname(public_ssh_key))
      unless `ssh-add -l`.match(/#{File.basename(private_ssh_key)}/)
        `ssh-add $HOME/.ssh/#{private_ssh_key}`
      end
    end

    def install_gems_to_bootstrap_chef
      remote_gem 'bundler', :version => gems[:bundler]
      remote_gem 'chef',    :version => gems[:chef]
      remote_gem 'rspec',   :version => gems[:rspec] # Required because we do Test-Driven Chef (TDC)!
    end

    def install_rvm
      remote_execute rvm_multi_user_install
      add_root_user_to_rvm_group
      apt_get_rvm_packages
      remote_execute "#{source_rvm_sh} && rvm install #{ruby_version}"
      remote_execute "#{source_rvm_sh} && rvm use #{ruby_version} --default"
    end

    def rvm_multi_user_install
      'curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o rvm-installer ; chmod +x rvm-installer ; sudo -s ./rvm-installer --version latest'
    end

    def source_rvm_sh
      "source /etc/profile.d/rvm.sh"
    end

    def add_root_user_to_rvm_group
      remote_execute "usermod -a -G rvm root"
    end

    def is_ssh_copy_id_installed_locally?
      `which ssh-copy-id`.length > 0
    end

    def copy_ssh_key_to_remote
      raise "ssh-copy-id is not installed locally! On the Mac, do 'brew install ssh-copy-id'" unless is_ssh_copy_id_installed_locally?
      is_ssh_key_in_local_known_hosts_file = `grep "#{ip_address}" ~/.ssh/known_hosts`.length > 0
      if is_ssh_key_in_local_known_hosts_file
        execute %Q{expect -c 'spawn ssh-copy-id -i $env(HOME)/.ssh/#{public_ssh_key} #{user}@#{ip_address}; expect assword ; send "#{password}\\n" ; interact'}
      else
        execute %Q{expect -c 'spawn ssh-copy-id -i $env(HOME)/.ssh/#{public_ssh_key} #{user}@#{ip_address}; expect continue; send "yes\\n"; expect assword ; send "#{password}\\n" ; interact'}
      end
    end

    def quiet?
      @quiet
    end

    def remote_gem(gem_name, options={ })
      if options[:version]
        version = options[:version]
        raise ArgumentError.new unless version.match(/^\d[.\d]+\d/)
        version_info = "-v #{version}"
      end
      remote_execute "#{source_rvm_sh} && gem install #{gem_name} #{version_info} --no-rdoc --no-ri"
    end

    def remote_apt_get(package_name)
      remote_execute "apt-get install -y #{package_name}"
    end

    def update_linux_distribution
      remote_execute 'apt-get update && apt-get --yes upgrade'
    end
  end
end
