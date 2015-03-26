app_name = "sandy"

yum_package 'ca-certificates' do
	action :nothing
end.run_action(:upgrade)

include_recipe 'yum-epel'

node.default['postgresql']['pg_hba'] += [{
	:type => 'host',
	:db => node[app_name]['database']['database'],
	:user => node[app_name]['database']['username'],
	:addr => 'all',
	:method => 'trust'
},{
  :type => 'host',
  :db => 'postgres',
  :user => node[app_name]['database']['username'],
  :addr => 'all',
  :method => 'trust'
}]

include_recipe 'postgresql::server'
include_recipe 'database::postgresql'
include_recipe 'postgresql::ruby'
include_recipe 'chef-vault'

postgresql_connection_info = {
	host: '127.0.0.1',
	port: 5432,
	username: 'postgres',
	password: chef_vault_item(:sandy, 'database')['passwords']['postgres'] #node['postgresql']['password']['postgres']
}

# create a postgresql database
postgresql_database node[app_name]['database']['database'] do
  connection postgresql_connection_info
  action :create
end

# Create a postgresql user but grant no privileges
postgresql_database_user node[app_name]['database']['username'] do
  connection postgresql_connection_info
  password   chef_vault_item(:sandy, 'database')['passwords'][node[app_name]['database']['username']]  #node[app_name]['database']['password']
  action     :create
end

# Grant all privileges on all tables in foo db
postgresql_database_user node[app_name]['database']['username'] do
  connection    postgresql_connection_info
  database_name  node[app_name]['database']['database']
  privileges    [:all]
  action        :grant
end
