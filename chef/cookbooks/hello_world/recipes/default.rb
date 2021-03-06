template "/tmp/hello_world.txt" do
  source "hello_world.txt.erb"
  owner 'root'
  group 'staff'
  mode "644"
  variables(:color => node['color'], :ip_address => node['ip_address'], :rails_env => node['rails_env'])
end

ruby_block "test" do
  block do
    puts `rspec -f progress #{File.expand_path(File.join(File.dirname(__FILE__), '../../../spec/hello_world/default_spec.rb'))}`
  end
end
