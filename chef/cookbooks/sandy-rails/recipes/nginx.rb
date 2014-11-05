node.default!['nginx']['default_site_enabled'] = false
include_recipe 'nginx'

ruby_block 'move_nginx_confs' do
  block do
    if File.exists? '/etc/nginx/conf.d'
      FileUtils::rm_rf '/etc/nginx/conf.d'
    end
  end
end

template "/etc/nginx/sites-available/sandy_site" do
  source 'nginx_site.erb'
  variables({
    install_path: "#{node['sandy']['paths']['application']}/current",
    # shared_path: node['sandy']['paths']['shared'],
    socket: "#{node['unicorn']['listen']}/sandy.socket",
    name: 'sandy',
    user: node['sandy']['account'],
    environment: node['sandy']['environment']
  })
end

nginx_site "sandy_site"
