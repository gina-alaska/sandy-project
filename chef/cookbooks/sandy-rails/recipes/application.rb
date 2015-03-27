include_recipe "chef-vault"
include_recipe "git"
include_recipe "sandy::packages"
include_recipe "sandy::ruby"
include_recipe "postgresql::client"

user node['sandy']['account']

gem_package "bundler" do
  gem_binary ::File.join('/opt/rubies', "ruby-#{node['sandy']['ruby']['version']}", 'bin/gem')
end

directory '/www' do
  owner node['sandy']['account']
  group node['sandy']['account']
  action :create
end

git node['sandy']['paths']['application'] do
  repo node['sandy']['git-repo']
  revision node['sandy']['git-revision']
  action :sync
  user node['sandy']['account']
  group node['sandy']['account']
  depth 1
end

%w{config config/initializers log tmp tmp/pids pids}.each do |dir|
  directory ::File.join(node['sandy']['paths']['application'], dir) do
    owner node['sandy']['account']
    group node['sandy']['account']
  end
end

node.default['sandy']['database']['password'] = chef_vault_item(:sandy, 'database')['passwords']['sandy']

db_master = search(:node, 'roles:sandy-database').first
db_master = node if db_master.nil?

template "#{node['sandy']['paths']['application']}/config/database.yml" do
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 00644
  variables({
    environment: node['sandy']['environment'],
    database: node['sandy']['database'],
    hostname: db_master['ipaddress']
  })
end

influx_servers = search(:node, 'roles:sandy-influxdb').map(&:ipaddress)
template "#{node['sandy']['paths']['application']}/config/initializers/influxdb-rails.rb" do
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 00644
  variables({
    database: 'sandy-metrics',
    username: 'sandy',
    password: data_bag_item(:sandy, 'influxdb')['users']['sandy']['password'],
    hosts: influx_servers
  })
end

ruby_block "squish-database-attributes" do
  block do
    node.rm('sandy','database','password')
  end
  subscribes :create, "template[#{node['sandy']['paths']['application']}/config/database.yml]"
end

template "#{node['sandy']['paths']['application']}/config/secrets.yml" do
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 00600
  variables({
    environment: node['sandy']['environment'],
    secrets: node['sandy']['rails']['secrets']
  })
end

redis_master = search(:node, 'roles:sandy-redis').first
redis_master = node if redis_master.nil?

template "#{node['sandy']['paths']['application']}/config/initializers/sidekiq.rb" do
  source "sidekiq_initializer.rb.erb"
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 0644
  variables({
    url: "redis://#{redis_master['ipaddress']}:6379",
    namespace: node['sandy']['redis']['namespace']
  })
end

execute 'bundle-install' do
  command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle install --deployment"
  cwd "#{node['sandy']['paths']['application']}"
  environment({"BUNDLE_BUILD__PG" => "--with-pg_config=/usr/pgsql-#{node['postgresql']['version']}/bin/pg_config"})
  action :nothing
  user node['sandy']['account']
  group node['sandy']['account']
  subscribes :run, "git[#{node['sandy']['paths']['application']}]", :delayed
end
