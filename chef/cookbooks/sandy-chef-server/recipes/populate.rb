local_server = {
  chef_server_url: 'https://localhost',
  options: {
    client_name: node['chef_server_populator']['user'],
    signing_key_filename: node['chef_server_populator']['pem']
  }
}

chef_data_bag 'dhcp_networks' do
  chef_server local_server
end

search('dhcp_networks', '*:*' ) do |item|
  chef_data_bag_item item['id'] do
    chef_server local_server
    data_bag 'dhcp_networks'
    raw_data(item.to_hash)
  end
end
