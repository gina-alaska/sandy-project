local_server = {
  chef_server_url: 'https://localhost',
  options: {
    client_name: 'admin',
    signing_key_filename: '/etc/chef-server/admin.pem'
  }
}

client_key_file = "/etc/chef/client.pem"

node.set['chef_client']['config'] = {
  chef_server_url: "https://localhost",
  node_name: node['fqdn'],
  client_key: client_key_file
}


key = OpenSSL::PKey::RSA.new(2048)

file client_key_file do
  content key.to_pem
  mode 0600
end

chef_client node['fqdn'] do
  chef_server local_server
  source_key key.public_key
  validator false
end

chef_node node['fqdn'] do
  chef_server local_server
  run_list []
end


include_recipe "chef-client::config"

# chef_server_url 'https://localhost'
# node_name 'admin'
# client_key 'admin.pem'
