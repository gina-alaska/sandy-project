node.default['sandy']['rails']['symlinks']['config/sidekiq.yml'] = 'config/sidekiq.yml'

include_recipe 'runit'
include_recipe 'sandy::application'

concurrency = node['sandy']['worker']['concurrency'] || node['cpu']['total']

template "#{node['sandy']['paths']['config']}/sidekiq.yml" do
  source "sidekiq.yml.erb"
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 0644
  variables({
    concurrency: concurrency,
    queues: node['sandy']['worker']['queues']
  })
  notifies :restart, "runit_service[sidekiq]"
end

link "#{node['sandy']['paths']['application']}/current/config/sidekiq.yml" do
  to "#{node['sandy']['paths']['config']}/sidekiq.yml"
end

#Check out worker repo
#Set path information

git node['sandy']['worker']['scripts-path'] do
  repository node['sandy']['worker']['scripts-git-repo']
  revision node['sandy']['worker']['scripts-git-revision']
  action node['sandy']['worker']['scripts-git-action']
  notifies :run, "execute[bundle-install]"
end

execute 'bundle-install' do
  command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle install --deployment"
  cwd node['sandy']['worker']['scripts-path']
end

runit_service 'sidekiq' do
  log true
  default_logger true
  env({
    "PATH" => "/usr/bin:/bin:#{node['sandy']['worker']['scripts-path']}/bin"
  })
  options({
    user: node['sandy']['account'],
    rubyversion: node['sandy']['ruby']['version'],
    app_dir: "#{node['sandy']['paths']['application']}/current",
    environment: node['sandy']['environment']
  })
end
